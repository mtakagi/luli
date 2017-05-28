open Core.Std

type 'a t = ('a -> unit) array

let create handlers =
  Array.of_list handlers

let notify t e  =
  Array.iter t ~f:(fun f -> f e)
