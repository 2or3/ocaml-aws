Open Types

type input = createTableRequest.t

type output = unit

type error = Errors_internal.type

include
  Aws.Call with type input := input and type output := output and type error := error
