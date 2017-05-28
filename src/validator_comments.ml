open Core.Std

let comment_type s n =
  let rec scan i a =
    if i < 0 then
      `Block
    else
      match String.get s i with
      | ' ' -> scan (i-1) (a+1)
      | '\t' -> scan (i-1) a
      | _ -> `Inline a
  in
  scan (n-1) 0

let bad_start ctx ~loc ~comment ~type_ ~code =
  (* "-- " で開始しているか *)
  match Annot.(comment.range) with
  | `Long -> ()
  | `Short ->
    if not @@ String.for_all comment.contents ~f:(fun c -> c = '-') then
      match String.lfindi comment.contents ~f:(fun _i c -> c <> ' ') with
      | None -> ()
      | Some 1 -> ()
      | Some 0 -> Context.add_errcode ctx loc code
      | Some _ ->
        match type_ with
        | `Block -> ()
        | `Inline -> Context.add_errcode ctx loc code

(* E101 *)
let mixed_chars ctx ~loc =
  let scan = Context.backward_scan ctx ~loc in
  match Scanner.scan_indent scan with
  | None -> `OK
  | Some idt' ->
    if Scanner.end_of_line scan then begin
      let actual = Scanner.Indent.depth idt' in
      if Scanner.Indent.contains_tabs idt' then begin
        let pos = File.shift_pos_exn (Context.file ctx)
            ~pos:loc.start ~len:(-actual) in
        let prev = Location.create pos loc.start in
        Context.add_errcode ctx prev Indent_with_mixed_chars;
        `Error
      end else
        `OK
    end else
      `OK

let is_aligned depth =
  depth mod !Conf.indent_size = 0

let block_indent ctx ~expected ~actual ~loc =
  if actual = expected then
    ()
  else if is_aligned expected && not @@ is_aligned actual then
    Context.add_errcode ctx loc Invalid_indent_size
  else if actual < expected then
    Context.add_errcode ctx loc Indented_block_expected
  else if actual > expected then
    Context.add_errcode ctx loc Unexpected_indent

let visual_indent ctx ~expected ~actual ~loc =
  if actual = expected then
    ()
  else if actual < expected then
    Context.add_errcode ctx loc Continuation_line_under_indented_for_visual_indent
  else if actual > expected then
    Context.add_errcode ctx loc Continuation_line_over_indented_for_visual_indent

let indent ctx ~(loc : Location.t) =
  let actual = loc.start.col in
  match Indent.find_lnum ~lnum:loc.start.line with
  | None -> (* no indent *)
    if mixed_chars ctx ~loc = `OK then
      block_indent ctx ~expected:0 ~actual ~loc
  | Some idt ->
    if mixed_chars ctx ~loc = `OK then begin
      let expected = idt.depth in
      match idt.line_type with
      | Logical_line ->
        block_indent ctx ~expected ~actual ~loc
      | Cont_line (Hanging, _) ->
        block_indent ctx ~expected ~actual ~loc
      | Cont_line (Visual, _) ->
        visual_indent ctx ~expected ~actual ~loc
    end

let f = function
  | Validator.Validate_file (_v, ctx, file) ->
    Array.iter file.lines ~f:(fun (line, (loc : Location.t)) ->
        List.iter (Annot.at_line loc) ~f:(fun ant ->
            match ant.desc with
            | Comment comment ->
              begin match comment_type line ant.loc.start.col with
              | `Block ->
                bad_start ctx ~loc:ant.loc ~comment ~type_:`Block
                  ~code:Bad_start_of_block_comment;
                indent ctx ~loc:ant.loc
              | `Inline prefix ->
                (* "--" 前のスペース *)
                if prefix < 2 then
                  Context.add_errcode ctx ant.loc
                    Missing_two_whitespaces_before_inline_comment;
                bad_start ctx ~loc:ant.loc ~comment ~type_:`Inline
                  ~code:Bad_start_of_inline_comment
              end
            | _ -> ()))
  | _ -> ()
