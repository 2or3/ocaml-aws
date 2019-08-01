open Types_internal
open Aws
type input = DescribeAlarmHistoryInput.t
type output = DescribeAlarmHistoryOutput.t
type error = Errors_internal.t
let service = "monitoring"
let to_http req =
  let uri =
    Uri.add_query_params (Uri.of_string "https://monitoring.amazonaws.com")
      (List.append
         [("Version", ["2010-08-01"]); ("Action", ["DescribeAlarmHistory"])]
         (Util.drop_empty
            (Uri.query_of_encoded
               (Query.render (DescribeAlarmHistoryInput.to_query req))))) in
  (`POST, uri, [])
let of_http body =
  try
    let xml = Ezxmlm.from_string body in
    let resp =
      Util.option_bind (Xml.member "DescribeAlarmHistoryResponse" (snd xml))
        (Xml.member "DescribeAlarmHistoryResult") in
    try
      Util.or_error (Util.option_bind resp DescribeAlarmHistoryOutput.parse)
        (let open Error in
           BadResponse
             {
               body;
               message =
                 "Could not find well formed DescribeAlarmHistoryOutput."
             })
    with
    | Xml.RequiredFieldMissing msg ->
        let open Error in
          `Error
            (BadResponse
               {
                 body;
                 message =
                   ("Error parsing DescribeAlarmHistoryOutput - missing field in body or children: "
                      ^ msg)
               })
  with
  | Failure msg ->
      `Error
        (let open Error in
           BadResponse { body; message = ("Error parsing xml: " ^ msg) })
let parse_error code err =
  let errors = [Errors_internal.InvalidNextToken] @ Errors_internal.common in
  match Errors_internal.of_string err with
  | Some var ->
      if
        (List.mem var errors) &&
          ((match Errors_internal.to_http_code var with
            | Some var -> var = code
            | None -> true))
      then Some var
      else None
  | None -> None