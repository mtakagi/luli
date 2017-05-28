open Ast_types
open Core.Std
open Env

let is_snake_case s =
  s = (String.lowercase s)

let is_anon_arg name =
  String.is_prefix name ~prefix:"_"

let validate_unused_vars ctx env =
  Env.iter env (fun var ->
    if not var.global && not var.used then begin
      (* 組み込み変数は対象外 *)
      match var.loc with 
      | Some loc -> Context.add_errcode ctx loc @@ Unused_var var.name
      | None -> ()
    end)

let validate_defined_var ctx (name : word) =
  match Context.find ctx name.desc with
  | None -> ()
  | Some var ->
    let code =
      match var.loc with
      | None -> Linterr.Code.Local_var_hides_embedded_var name.desc
      | Some loc ->
        let pos = Location.(loc.start) in
        if var.global then
          Local_var_hides_global_var
            (name.desc, (Context.file ctx).path, pos.line + 1)
        else
          Local_var_hides_outer_local_var (name.desc, pos.line + 1)
    in
    Context.add_errcode ctx name.loc code

let validate_var ctx (name : word) =
  (* 変数は定義済みか *)
  begin match Context.find ctx name.desc with
  | Some var -> var.used <- true
  | None ->
    let code =
      if !Conf.spell_check then
        match Context.suggest ctx name.desc with
        | Some other ->
          Linterr.Code.Unassigned_var_with_suggestion (name.desc, other.name)
        | None -> Unassigned_var name.desc
      else
        Unassigned_var name.desc
    in
    Context.add_errcode ctx name.loc code
  end

let f = function
  | Validator.Validate_env_end (_v, ctx, env) ->
    validate_unused_vars ctx env

  | Validator.Validate_ast_begin (_v, ctx, ast) ->
    begin match ast.desc with
    | Num_for (_for_, name, _eq, _init_exp, _comma1, _max_exp,
               _step_opt, _do_, _chunk, _end_) ->
      let var = Var.with_locd name in
      var.used <- true;
      Context.set ctx var

    | Gen_for (_for_, namelist, _in_, _explist, _do_, _chunk, _end_) ->
      let vars = Seplist.map_a namelist.desc
          ~f:(fun name ->
              let var = Var.with_locd name in
              var.used <- true;
              var)
      in
      List.iter vars ~f:(Context.set ctx)

    | Func_def (_fun_, names, _body) ->
      let name = Seplist.hd names.desc in
      if Seplist.length names.desc > 1 then begin
        (* function foo.bar.baz の形式 *)
        validate_var ctx name
      end else begin
        let var = Var.with_locd name in
        Context.set ctx var;
        if Context.is_top_env ctx then begin
          (* グローバル関数 *)
          Context.add_errcode ctx name.loc @@ Global_func_def name.desc;
          Context.set_global ctx var
        end
      end

    | Method_def (_fun_, (_names, _colon, _meth), _body) ->
      (* TODO *)
      let self = Var.with_locd (Location.with_loc ast.loc "self") in
      self.used <- true;
      Context.set ctx self;
      ()

    | Local_func_def (_local_, _fun_, name, _body) ->
      if not @@ is_snake_case name.desc then begin
        Context.add_errcode ctx name.loc @@ Not_snake_case name.desc
      end;
      Context.set ctx @@ Var.with_locd name

    | Local_var_def (_local, namelist, explist_opt) ->
      let names = Seplist.elements_a namelist.desc in
      List.iter names
        ~f:(fun name ->
              begin match Context.find ~recur:false ctx name.desc with
              | Some _ ->
                Context.add_errcode ctx name.loc @@ Local_var_exists name.desc
              | None ->
                begin match Context.find ctx name.desc with
                | None -> ()
                | Some _ -> validate_defined_var ctx name
                end
              end;
              Context.set ctx @@ Var.with_locd name);

      (* 初期値が匿名関数かどうか *)
      begin match explist_opt with
      | None -> ()
      | Some (_, (explist : explist)) ->
        let exps = Seplist.elements_a explist.desc in
        let len = List.length names in
        List.iteri exps
          ~f:(fun i exp ->
                match exp.desc with
                | Func _ ->
                  let code =
                    if i < len then
                      Linterr.Code.Init_assign_to_anon_func_with_name
                        (List.nth_exn names i).desc
                    else
                      Init_assign_to_anon_func
                  in
                  Context.add_errcode ctx exp.loc code
                | _ -> ())
      end

    | Var var ->
      begin match var.desc with
      | Ast_types.Atom name -> validate_var ctx name
      | Field_ref (_table, _, _field) -> ()
      | Subscription (_target, _, key, _) ->
        if Ast.is_zero key then
          Context.add_errcode ctx key.loc Element_zero
      end

    | _ -> ()
    end

  | Validator.Validate_ast_end (_v, ctx, ast) ->
    begin match ast.desc with
    | Assign (varlist, _eq, _explist) ->
      let register (var : Ast_types.var) =
        match var.desc with
        | Ast_types.Atom name ->
          begin match Context.find ctx name.desc with
          | Some evar ->
            if evar.global then
              Context.add_errcode ctx name.loc @@ Reassign_global_var name.desc
          | None ->
            let evar = Var.with_locd name in
            if Context.is_top_env ctx then begin
              Context.add_errcode ctx name.loc @@ Global_var_def name.desc;
              Context.set_global ctx evar
            end else begin
              Context.set ctx evar
            end
          end
        | Field_ref (_table, _, _field) -> ()
        | _ -> ()
      in
      let vars = Seplist.elements_a varlist.desc in
      List.iter vars ~f:(fun var -> register var)
    | _ -> ()
    end

  | Validate_funcbody_begin (_v, ctx, ast) ->
    let (_lp, parlist_opt, _rp, _chunk, _end_) = ast.desc in
      begin match parlist_opt with
      | Some (parlist : parlist) ->
        begin match parlist.desc with
        | Par_names (names, vargs) ->
          List.iter (Seplist.elements_a names.desc)
            ~f:(fun name ->
                  let var = Var.with_locd name in
                  if !Conf.anon_args && is_anon_arg name.desc then
                    var.used <- true;
                  Context.set ctx var);
          begin match vargs with
          | Some (_, loc) -> Context.set_vargs ctx loc
          | None -> ()
          end
        | Par_vargs loc -> Context.set_vargs ctx loc
        end;
      | None -> ()
      end

  | _ -> ()
