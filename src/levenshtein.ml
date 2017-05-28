(**

   Levenshtein distance algorithm for general array.
   
   Author: jun.furuse@gmail.com
   License: public domain

*)

(** Minimum of three integers *)
let min3 (x:int) y z =
  let m' (a:int) b = if a < b then a else b in
  m' (m' x y) z

module type S = sig
  type t
  val distance : ?upper_bound: int -> t -> t -> int
  (** Calculate Levenshtein distance of 2 t's *)
end

module Make(A : sig 
  type t
  type elem
  val compare : elem -> elem -> int
  val get : t -> int -> elem
  val size : t -> int
end) = struct

  type t = A.t

  (* slow_but_simple + memoization + upperbound 

     There is a property: d(i-1)(j-1) <= d(i)(j)
     so if d(i-1)(j-1) >= upper_bound then we can immediately say
     d(i)(j) >= upper_bound, and skip the calculation of d(i-1)(j) and d(i)(j-1)
  *)
  let distance ?(upper_bound=max_int) xs ys =
    let size_xs = A.size xs 
    and size_ys = A.size ys in
    (* cache: d i j is stored at cache.(i-1).(j-1) *)
    let cache = Array.init size_xs (fun _ -> Array.make size_ys (-1)) in
    let rec d i j =
      match i, j with
      | 0, _ -> j
      | _, 0 -> i
      | _ -> 
          let i' = i - 1 in
          let cache_i = Array.unsafe_get cache i' in
          let j' = j - 1 in
          match Array.unsafe_get cache_i j' with
          | -1 ->
              let res = 
                let upleft = d i' j' in
                if upleft >= upper_bound then upper_bound
                else 
                  let cost = abs (A.compare (A.get xs i') (A.get ys j')) in
                  let upleft' = upleft + cost in
                  if upleft' >= upper_bound then upper_bound
                  else
                    (* This is not tail recursive *)
                    min3 (d i' j + 1)
                         (d i j' + 1)
                         upleft'
              in
              Array.unsafe_set cache_i j' res;
              res
          | res -> res
    in
    min (d size_xs size_ys) upper_bound

end

module String = struct

  include Make(struct
    type t = string
    type elem = char
    let compare (c1 : char) c2 = compare c1 c2
    let get = String.unsafe_get
    let size = String.length
  end)

end
