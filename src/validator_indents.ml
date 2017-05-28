open Core.Std

let is_aligned depth =
  depth mod !Conf.indent_size = 0

let validate_logical_line ?(func_end=false) ctx loc =
  let scan = Context.backward_scan ctx ~loc:loc in
  begin match Scanner.scan_indent scan with
  | None -> ()
  | Some indent ->
    if Scanner.end_of_line scan then begin
      let actual = Scanner.Indent.depth indent in
      if Scanner.Indent.contains_tabs indent then
        let pos = File.shift_pos_exn (Context.file ctx)
            ~pos:loc.start ~len:(-actual) in
        let prev = Location.create pos loc.start in
        Context.add_errcode ctx prev Indent_with_mixed_chars
      else begin
        let base = Context.current_indent_depth ctx in
        let prev = Context.prev_indent_depth ctx in
        let func_end_base = if func_end then base else prev in
        if actual = base then
          ()
        else if actual <> 0 &&
                not @@ is_aligned @@ actual - prev &&
                (not (Context.in_visual_indent ctx) ||
                 (Context.in_visual_indent ctx && actual > func_end_base)) then
          Context.add_errcode ctx loc Invalid_indent_size
        else if actual < base then
          Context.add_errcode ctx loc Indented_block_expected
        else if actual > base then
          Context.add_errcode ctx loc Unexpected_indent
      end
    end 
  end

let validate_visual_indent ctx loc ~actual ~close =
  let base = Context.current_indent_depth ctx in
  if Context.next_chunk_indent_depth ctx = Some actual then
    Context.add_errcode ctx loc
      Continuation_line_does_not_distinguish_itself_from_next_logical_line
  else if actual = base then
    ()
  else if close then
    Context.add_errcode ctx loc Closing_bracket_does_not_match_visual_indent
  else if actual < base then
    Context.add_errcode ctx loc Continuation_line_under_indented_for_visual_indent
  else
    Context.add_errcode ctx loc Continuation_line_over_indented_for_visual_indent

let validate_hang_indent ctx loc ~actual ~close =
  let next = Context.next_chunk_indent_depth ctx in
  let e125 = is_some next in
  let trail_close = Context.current_indent_close_type ctx =
                    Close_type.Trailing_close in
  let cur = Context.current_indent_depth ctx in
  let prev = Context.prev_indent_depth ctx in
  let base =
    if e125 && trail_close then
      cur + !Conf.indent_size
    else if close then
      prev
    else
      cur
  in
  if Option.exists next
      ~f:(fun next' -> (trail_close || close) && actual = next') then
    Context.add_errcode ctx loc
      Continuation_line_does_not_distinguish_itself_from_next_logical_line
  else if close && actual = cur then
    Context.add_errcode ctx loc Closing_bracket_does_not_match_indent_of_opening_bracket_line
  else if actual = base then
    ()
  else if not @@ is_aligned @@ actual - prev &&
          (not (Context.in_visual_indent ctx) ||
           (Context.in_visual_indent ctx && actual > prev)) then
    Context.add_errcode ctx loc Continuation_line_invalid_indent_size
  else if actual < base then
    Context.add_errcode ctx loc Continuation_line_missing_indent_or_outdented
  else
    Context.add_errcode ctx loc Continuation_line_over_indented_for_hanging_indent

let validate_cont_line ?(close=false) ctx loc =
  let indent_type = Context.current_indent_type ctx in
  if Indent_type.is_logical_line indent_type then
    ()
  else begin
    let scan = Context.backward_scan ctx ~loc in
    let indent = Scanner.scan_indent scan in
    if Scanner.end_of_line scan then begin
      match indent with
      | None -> ()
      | Some indent' ->
        let actual = Scanner.Indent.depth indent' in
        if Scanner.Indent.contains_tabs indent' then
          let pos = File.shift_pos_exn (Context.file ctx)
              ~pos:loc.start ~len:(-actual) in
          let prev = Location.create pos loc.start in
          Context.add_errcode ctx prev Indent_with_mixed_chars
        else begin
          match indent_type with
          | Indent_type.Visual_indent ->
            validate_visual_indent ctx loc ~actual ~close
          | Indent_type.Hanging_indent ->
            validate_hang_indent ctx loc ~actual ~close
          | _ -> ()
        end
    end
  end

let f = function
  | Validator.Validate_ast_begin (_v, ctx, ast) ->
    begin match ast.desc with
    | Do (_do_, _chunk, end_) ->
      validate_logical_line ctx end_

    | Num_for (_for_, _name, _eq, _init_exp, _comma1, _max_exp,
               _step_opt, _do_, _chunk, end_) ->
      validate_logical_line ctx end_

    | Gen_for (_for_, _namelist, _in_, _explist, _do_, _chunk, end_) ->
      validate_logical_line ctx end_

    | While (_while_, _cond, _do_, _chunk, end_) ->
      validate_logical_line ctx end_

    | Repeat (_repeat_, _chunk, until, _cond) ->
      validate_logical_line ctx until

    | If (condbodylist, else_opt, end_) ->
      (* elseif のみ検査する (if はチャンク内で検査される) *)
      begin match List.tl condbodylist with
      | None -> ()
      | Some tl -> List.iter tl ~f:(fun t -> validate_logical_line ctx t.loc)
      end;
      begin match else_opt with
      | Some (else_, _chunk) -> validate_logical_line ctx else_
      | None -> ()
      end;
      validate_logical_line ctx end_

    | Table (lb, _fieldlist_opt, _rb) ->
      validate_cont_line ctx lb

    | Key_assoc (_key, _eq, _exp) ->
      validate_cont_line ctx ast.loc

    | Expr_assoc (_lb, _keyexp, _rb, _eq, _valexp) ->
      validate_cont_line ctx ast.loc

    | Unary_expr (_op, _exp) ->
      validate_cont_line ctx ast.loc

    | Func _ ->
      validate_cont_line ctx ast.loc

    | Var _var ->
      validate_cont_line ctx ast.loc

    | Nil _tok ->
      validate_cont_line ctx ast.loc

    | Bool (_tok, _v) ->
      validate_cont_line ctx ast.loc

    | Number _v ->
      validate_cont_line ctx ast.loc

    | String (_quote, _v) ->
      validate_cont_line ctx ast.loc

    | Ellipsis _tok ->
      validate_cont_line ctx ast.loc

    | _ -> ()
    end

  | Validate_funcbody_begin (_v, ctx, ast) ->
    let (lb, parlist_opt, rb, _chunk, end_) = ast.desc in
    let (elements, vargs, last_elt_loc) =
      match parlist_opt with
      | None -> (None, None, None)
      | Some parlist ->
        let (names, vargs) = Ast.Parlist.params parlist in
        (names, vargs, Some (Ast.Parlist.last_elt_loc parlist))
    in
    Context.indent_next_chunk ctx;
    Context.parse_cont_lines ctx ~loc:ast.loc ~lb ~rb ~last_elt_loc ~elements
      ~f:(fun name -> validate_cont_line ctx name.loc)
      ~rb_f:(fun () ->
          Option.iter vargs ~f:(fun vargs -> validate_cont_line ctx vargs);
          validate_cont_line ctx rb ~close:true);
    Context.dedent_next_chunk ctx;
    validate_logical_line ctx end_ ~func_end:true

  | Validate_chunk_begin (_v, ctx, chunk) ->
    begin match chunk with
    | None -> ()
    | Some stats ->
      List.iter stats.desc ~f:(fun _t -> validate_logical_line ctx stats.loc)
    end

  | Validator.Validate_cont_line_end (_v, ctx, _lb, rb) ->
    validate_cont_line ctx rb ~close:true

  | _ -> ()
