# WaxDemo

A demo Phoenix application to test and showcase FIDO2 authentication using the
[Wax library](https://github.com/tanguilp/wax).

Screen capture: TODO

## How to run the demo

First Launch the application

```bash
$ iex -S mix phx.server
```

and then browse [http://localhost:4000](http://localhost:4000)

### Attestation

The attestation conveyance preference is set to:
- `direct` when the username is a palindrome, such as "bob" (case sensitive)
- `none` otherwise

Direct attestation requires the use of metadata statements. Follow the instruction on the
[Wax](https://github.com/tanguilp/wax) page to configure FIDO Alliance metadata access.

The demo will not ask for key registration if it doesn't support WebAuthn. In Firefox, you
can disable WebAuthn by typing `about:config` and then disabling the `security.webauth.webauthn`
preference.

## Demo structure

This is a standard Phoenix project with 4 controllers and templates for:
- Enter login page
- Credential page
- Register key page
- Personal page (simulating a private page that is shown after successful authentication)

The following baackends are used for storage:
- ETS for session storage (session don't survive server restart)
- DETS for user credential storage

The `WaxDemo.User` provides with convenience functions to deal with stored credentials:

```elixir
iex> WaxDemo.User.print_keys
{"John",
 "HIHu5VyMoWQl4o1ZBXKmHX/I4jJPG2RmYySqT01GnD4WNDJdAmMwFDBWHl1/XDIXTASBFYqC66+M+bx0N58yeA==",
 %{
   -3 => <<13, 7, 77, 184, 30, 112, 243, 135, 49, 154, 7, 31, 117, 221, 94, 68,
     152, 38, 28, 205, 33, 56, 81, 18, 249, 234, 92, 178, 111, 175, 60, 175>>,
   -2 => <<234, 146, 131, 152, 38, 10, 56, 66, 142, 166, 148, 159, 35, 212, 207,
     235, 79, 175, 163, 176, 21, 93, 13, 114, 147, 24, 247, 207, 152, 231, 57,
     34>>,
   -1 => 1,
   1 => 2,
   3 => -7
 }}
{"John",
 "cwxZDJENhZNu2EmpqisJKsHHy01vEZcnHTvvykv8ThQzzvazgZ4vw736k7IJHigdOlzWwaAZ48AgAPPC51YjBg==",
 %{
   -3 => <<161, 125, 243, 160, 150, 151, 232, 150, 100, 247, 164, 249, 192, 230,
     189, 41, 133, 249, 192, 252, 143, 221, 150, 248, 113, 11, 183, 105, 228,
     215, 137, 228>>,
   -2 => <<156, 83, 236, 174, 12, 102, 148, 212, 124, 212, 245, 73, 231, 23, 56,
     145, 214, 83, 132, 228, 146, 224, 84, 144, 141, 219, 213, 196, 242, 141,
     14, 29>>,
   -1 => 1,
   1 => 2,
   3 => -7
 }}
{"John",
 "bk9IENkj9Cy7kwPkojvCri2lAFA/NSFuP1kwjDQW3Sj5yFNl/o1v++mueLCiOqfPbkgRFEEdjwWwjGpvDKZKYw==",
 %{
   -3 => <<24, 153, 235, 124, 221, 103, 35, 224, 12, 57, 125, 26, 106, 34, 242,
     22, 53, 89, 53, 108, 29, 41, 169, 172, 101, 40, 19, 242, 204, 173, 251,
     248>>,
   -2 => <<178, 195, 66, 227, 132, 114, 106, 72, 137, 175, 16, 173, 133, 237,
     168, 54, 50, 60, 239, 38, 120, 8, 85, 114, 88, 113, 50, 113, 64, 248, 102,
     34>>,
   -1 => 1,
   1 => 2,
   3 => -7
 }}
{"Carole",
 "lMSL/l9HKFDFIBo5EQe62y31OvbtVy12I+YY9ZnTiw/KIS3F5RMaAEiMvjO3LUqfqpMj36i17Tm+3ShJWU2pcQ==",
 %{
   -3 => <<170, 244, 217, 93, 33, 50, 52, 11, 154, 15, 161, 219, 204, 82, 139,
     11, 80, 190, 243, 180, 175, 207, 162, 181, 219, 207, 174, 28, 231, 97, 87,
     80>>,
   -2 => <<23, 152, 128, 92, 212, 169, 6, 128, 165, 60, 59, 154, 114, 138, 174,
     12, 142, 112, 35, 72, 65, 134, 211, 194, 223, 64, 122, 197, 67, 83, 108,
     255>>,
   -1 => 1,
   1 => 2,
   3 => -7
 }}
{"Mike",
 "xI7v7dPEtf2E7hi2NE8IJwXWRZ92Pxr1fiY8RfzSwR5CgIjGKsB6eeMWQjr5MtVbrksD/0rsMXdZB0/Op4gxZw==",
 %{
   -3 => <<190, 193, 216, 250, 173, 199, 4, 99, 195, 168, 233, 127, 216, 91, 49,
     94, 78, 19, 245, 52, 121, 181, 190, 202, 75, 26, 158, 249, 128, 196, 115,
     143>>,
   -2 => <<63, 80, 199, 246, 196, 208, 185, 74, 4, 240, 211, 185, 154, 78, 93,
     153, 55, 73, 10, 252, 168, 64, 228, 112, 190, 21, 41, 38, 207, 195, 41,
     14>>,
   -1 => 1,
   1 => 2,
   3 => -7
 }}
{"Mike",
 "/nvZqvoCxxc2fn6zBEeoeBT2YczbzI3gY5JMO2o83xmriTcD83U6qIttnt8KOc4+CFuhrWPSFZRFfUVXRs1q+g==",
 %{
   -3 => <<113, 84, 239, 1, 97, 9, 90, 121, 203, 13, 250, 227, 234, 3, 203, 223,
     51, 164, 19, 229, 114, 206, 134, 108, 193, 107, 9, 123, 137, 147, 45, 74>>,
   -2 => <<73, 138, 112, 68, 184, 174, 179, 38, 65, 94, 77, 205, 139, 52, 15, 0,
     60, 108, 220, 27, 155, 80, 141, 40, 232, 158, 192, 12, 104, 57, 40, 29>>,
   -1 => 1,
   1 => 2,
   3 => -7
 }}
[]
iex> WaxDemo.User.clean_keys
:ok
iex> WaxDemo.User.print_keys
[]
```
