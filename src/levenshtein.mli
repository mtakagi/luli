(**

   Levenshtein distance algorithm for general array.

   Author: jun.furuse@gmail.com
   License: public domain

*)

module type S = sig
  type t
  val distance : ?upper_bound: int -> t -> t -> int
  (** Calculate Levenshtein distance of 2 t's.
      
      If we are only interested in the distance if it is smaller than 
      a threshold, specifying [upper_bound] greatly improves the performance
      of [distance]. In that case, the distances over [upper_bound] is 
      culled to [upper_bound].
  *)
end

module Make(A : sig
  type t
  (** Type of arrays *)

  type elem 
  (** Type of the elements of arrays *)

  val compare : elem -> elem -> int
  val get : t -> int -> elem
  val size : t -> int

end) : S with type t = A.t

module String : S with type t = string

