open Ast_types
open Core.Std

let validate_multi_stats ctx stats =
  let rec iter (stats : ast list) last =
    match stats with
    | [] -> ()
    | hd :: tl ->
      match hd.desc with
      | Nop semi ->
        begin match List.hd tl with
        | None ->
          Context.add_errcode ctx semi Stat_ends_with_semi_colon
        | Some next ->
          if semi.start.line = next.loc.start.line then
            Context.add_errcode ctx semi Stats_on_line_by_semi_colon
          else
            Context.add_errcode ctx semi Stat_ends_with_semi_colon
        end;
        iter tl hd
      | _ ->
        match last.desc with
        | Nop _ -> iter tl hd
        | _ ->
          if last.loc.start.line = hd.loc.start.line then
            Context.add_errcode ctx hd.loc Stats_on_line;
          iter tl hd
  in
  match stats with
  | [] -> ()
  | hd :: tl -> iter tl hd

let f = function
  | Validator.Validate_chunk_begin (_v, ctx, chunk) ->
    begin match chunk with
    | None -> ()
    | Some stats -> validate_multi_stats ctx stats.desc
    end
  | _ -> ()
