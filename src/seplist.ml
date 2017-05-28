open Core.Std

type ('a, 'b) t = C of 'a * ('b, 'a) t option

type ('a, 'b) rev =
  | RevA of ('a, 'b) t
  | RevB of ('b, 'a) t

type ('a, 'b) either =
  | A of 'a
  | B of 'b

let create e =
  C (e, None)

let add e es =
  C (e, Some es)

let hd = function
  | C (e, _) -> e

let tl = function
  | C (_, es) -> es

let last l =
  let rec iter_a a = function
    | None -> a
    | Some es -> iter_b (A (hd es)) (tl es) 
  and iter_b a = function
    | None -> a
    | Some es -> iter_a (B (hd es)) (tl es)
  in
  iter_b (A (hd l)) (tl l)

let rev_add l e =
  C (e, Some l)

let rev_add_pair l e1 e2 =
  rev_add (rev_add l e1) e2

let rev l =
  let rec iter_a a = function
    | None -> RevB a
    | Some es -> iter_b (add (hd es) a) (tl es) 
  and iter_b a = function
    | None -> RevA a
    | Some es -> iter_a (add (hd es) a) (tl es)
  in
  iter_b (create (hd l)) (tl l)

let of_a_rev = function
  | RevA l -> l
  | RevB _ -> failwith "of_a_rev"

let of_b_rev = function
  | RevA _ -> failwith "of_b_rev"
  | RevB l -> l

let fold (l : ('a, 'b) t) ~(init : 'accu)
            ~(fa : ('accu -> 'a -> 'accu))
            ~(fb : ('accu -> 'b -> 'accu)) =
  let rec fold_a accu e es_opt =
    let accu' = fa accu e in
    match es_opt with
    | None -> accu'
    | Some es -> fold_b accu' (hd es) (tl es)
  and fold_b accu e es_opt =
    let accu' = fb accu e in
    match es_opt with
    | None -> accu'
    | Some es -> fold_a accu' (hd es) (tl es)
  in
  fold_a init (hd l) (tl l)

let iter (l : ('a, 'b) t) ~(fa : ('a -> unit)) ~(fb : ('b -> unit)) =
  fold l ~init:() ~fa:(fun _ a -> fa a) ~fb:(fun _ b -> fb b)

let iteri (l : ('a, 'b) t) ~(fa : (int -> 'a -> unit))
             ~(fb : (int -> 'b -> unit)) =
  let _ = fold l ~init:0
    ~fa:(fun i a -> fa i a; i + 1)
    ~fb:(fun i b -> fb i b; i + 1)
  in
  ()

let length l =
  fold l ~init:0 ~fa:(fun len _ -> len + 1) ~fb:(fun len _ -> len + 1)

let length_a l =
  fold l ~init:0 ~fa:(fun len _ -> len + 1) ~fb:(fun len _ -> len)

let length_b l =
  fold l ~init:0 ~fa:(fun len _ -> len) ~fb:(fun len _ -> len + 1)

let is_singleton = function
  | C (_, None) -> true
  | _ -> false

let elements_a l =
  List.rev @@ fold l ~init:[] ~fa:(fun accu a -> a :: accu)
                ~fb:(fun accu _ -> accu)

let elements_b l =
  List.rev @@ fold l ~init:[] ~fa:(fun accu _ -> accu)
                ~fb:(fun accu b -> b :: accu)

let map_a l ~f =
  List.map (elements_a l) ~f
