```elixir
$ MIX_ENV="test" iex -S mix
iex(1)> ExUnit.start()
:ok
iex(2)> c "test/test_data_helper.exs"
[Merkel.TestDataHelper]
iex(3)> c "test/test_helper.exs"
[Merkel.TestHelper]
iex(4)> c "test/merkel/tree_prop_test.exs"
[Merkel.TreePropTest]
```
```elixir
iex(5)> :proper_gen.pick(Merkel.TreePropTest.generate_tree(:option_min_four_tree)) 
{:ok,
 {#Merkel.Tree<{11,
   {"1c0b3fd4c855c73be46674274fe93aadbce778abe658f8dc7609b32e0009505b",
    "<=Pa..>", 4,
    {"4fd4..", "<=5n..>", 3,
     {"5281..", "<=1K..>", 2,
      {"b52a..", "<=..>", 1, {"e3b0..", "", 0}, {"3bb4..", "1K1VUQe", 0}},
      {"c508..", "5nUn5j", 0}},
     {"63ab..", "<=Ab..>", 2,
      {"7d90..", "<=8..>", 1, {"2c62..", "8", 0}, {"9e7d..", "AbO5yut", 0}},
      {"37a8..", "PayBYPCDG", 0}}},
    {"cf50..", "<=o..>", 3,
     {"20fc..", "<=lL..>", 2,
      {"be7c..", "<=W7..>", 1, {"a025..", "W7A", 0},
       {"47e9..", "lLHFfoBPEd", 0}}, {"65c7..", "o", 0}},
     {"0d48..", <<163, 242>>, 1,
      {"6e20..", <<163, 242, 62, 183, 209, 8, 25, 113, 160>>, 0},
      {"6033..", <<194, 176, 11, 189, 137, 14, 47, 129, 12, 94>>, 0}}}}}>,
  [
    {"1K1VUQe", -1.3789317543904047},
    {"8", 3},
    {"5nUn5j", 26.852740399500124},
    {"o", -1.0160044166486373},
    {"", :"\x92"},
    {<<163, 242, 62, 183, 209, 8, 25, 113, 160>>, 7.496176300512326},
    {"W7A", 8},
    {"PayBYPCDG", -4},
    {"lLHFfoBPEd", "wy"},
    {<<194, 176, 11, 189, 137, 14, 47, 129, 12, 94>>, 73.01214022127897},
    {"AbO5yut", :"w\x05"}
  ],
  [
    "",
    "1K1VUQe",
    "5nUn5j",
    "8",
    "AbO5yut",
    "PayBYPCDG",
    "W7A",
    "lLHFfoBPEd",
    "o",
    <<163, 242, 62, 183, 209, 8, 25, 113, 160>>,
    <<194, 176, 11, 189, 137, 14, 47, 129, 12, 94>>
  ], "1K1VUQe", 11}}
```
```elixir
iex(6)> :proper_gen.pick(Merkel.TreePropTest.generate_tree(:option_min_one_tree))  
{:ok,
 {#Merkel.Tree<{4,
   {"9b5378f0ca095b1e106c795d16a93ca34f9c6d851e37a300441707e9084d8b6c",
    "<=qd..>", 2,
    {"5f0c..", "<=a4..>", 1, {"9045..", "a4y9MVW", 0}, {"8a60..", "qdKLAH", 0}},
    {"0c3b..", "<=u..>", 1, {"0bfe..", "u", 0}, {"63ce..", "xRMVGkW7Mu", 0}}}}>,
  [
    {"xRMVGkW7Mu", :"O\x80Ë×¡e"},
    {"qdKLAH", :"=8Ôb\d"},
    {"a4y9MVW", "y"},
    {"u", -6}
  ], ["a4y9MVW", "qdKLAH", "u", "xRMVGkW7Mu"], "xRMVGkW7Mu", 4}}
  ```
  ```elixir
iex(7)> use PropCheck                                            
PropCheck.TargetedPBT
```
```elixir
iex(8)> sample_shrink(Merkel.TreePropTest.unique_kv_pairs_list())
[{<<"0VWd29TyU">>,-15},
 {<<"y">>,5},
 {<<"nl0z">>,'³'},
 {<<"o">>,-71},
 {<<"XBKJ4pa2mU">>,-2.112760294833219},
 {<<"5l8OT">>,4}]
[{<<"0VWd29TyU">>,-15},{<<"y">>,5},{<<"nl0z">>,'³'}]
[{<<"y">>,5},{<<"nl0z">>,'³'}]
[{<<"nl0z">>,'³'}]
[{<<"nl">>,'³'}]
[{<<"l">>,'³'}]
[{<<"A">>,'³'}]
[{<<"A">>,1}]
[{<<"A">>,0}]
:ok
```
```elixir
iex(9)> generator = fn() -> Merkel.TreePropTest.kv_pairs_list(:atleast_four) end
#Function<21.91303403/0 in :erl_eval.expr/5>
```
```elixir
iex(10)> sample_shrink(Merkel.TreePropTest.unique_kv_pairs_list(generator))     
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOLd8DWOnS">>,14.829839030779532},
 {<<"G1FvfvgK5">>,4.649627366501582},
 {<<"eKkB">>,11.123432807491671},
 {<<"dA1rL">>,0.44012177370998223},
 {<<"c1wd1Cy4L1">>,'\237Tð#\tL'},
 {<<"½Rò(Ü-\v">>,<<"lbpiyuwf">>},
 {<<"Q4Xq">>,-3.2102621792071826},
 {<<"A">>,13},
 {<<"2rUUiL">>,8},
 {<<24,168>>,''}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOLd8DWOnS">>,14.829839030779532},
 {<<"G1FvfvgK5">>,4.649627366501582},
 {<<"eKkB">>,11.123432807491671},
 {<<"dA1rL">>,0.44012177370998223},
 {<<"c1wd1Cy4L1">>,'\237Tð#\tL'},
 {<<"½Rò(Ü-\v">>,<<"lbpiyuwf">>}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOLd8DWOnS">>,14.829839030779532},
 {<<"G1FvfvgK5">>,4.649627366501582},
 {<<"eKkB">>,11.123432807491671},
 {<<"dA1rL">>,0.44012177370998223}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOLd8DWOnS">>,14.829839030779532},
 {<<"eKkB">>,11.123432807491671},
 {<<"dA1rL">>,0.44012177370998223}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOLd8DWOnS">>,14.829839030779532},
 {<<"dA1rL">>,0.44012177370998223}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOLd8DWOnS">>,14.829839030779532},
 {<<"dA1">>,0.44012177370998223}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOLd8DWOnS">>,14.829839030779532},
 {<<"A1">>,0.44012177370998223}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOLd8DWOnS">>,14.829839030779532},
 {<<"1">>,0.44012177370998223}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOLd8DWOnS">>,14.829839030779532},
 {<<"A">>,0.44012177370998223}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOLd8DWOnS">>,14.829839030779532},
 {<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOLd8">>,14.829839030779532},
 {<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"TOL">>,14.829839030779532},
 {<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"OL">>,14.829839030779532},
 {<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"L">>,14.829839030779532},
 {<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"B">>,14.829839030779532},
 {<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},
 {<<"46xcvesqV">>,<<"4|)ÓX">>},
 {<<"B">>,0},
 {<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},{<<"46xcv">>,<<"4|)ÓX">>},{<<"B">>,0},{<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},{<<"46x">>,<<"4|)ÓX">>},{<<"B">>,0},{<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},{<<"6x">>,<<"4|)ÓX">>},{<<"B">>,0},{<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},{<<"x">>,<<"4|)ÓX">>},{<<"B">>,0},{<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},{<<"C">>,<<"4|)ÓX">>},{<<"B">>,0},{<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},{<<"C">>,29},{<<"B">>,0},{<<"A">>,0}]
[{<<"SpOFfjnNi">>,<<"a">>},{<<"C">>,0},{<<"B">>,0},{<<"A">>,0}]
[{<<"SpOFf">>,<<"a">>},{<<"C">>,0},{<<"B">>,0},{<<"A">>,0}]
[{<<"SpO">>,<<"a">>},{<<"C">>,0},{<<"B">>,0},{<<"A">>,0}]
[{<<"pO">>,<<"a">>},{<<"C">>,0},{<<"B">>,0},{<<"A">>,0}]
[{<<"O">>,<<"a">>},{<<"C">>,0},{<<"B">>,0},{<<"A">>,0}]
[{<<"D">>,<<"a">>},{<<"C">>,0},{<<"B">>,0},{<<"A">>,0}]
[{<<"D">>,-9},{<<"C">>,0},{<<"B">>,0},{<<"A">>,0}]
[{<<"D">>,0},{<<"C">>,0},{<<"B">>,0},{<<"A">>,0}]
:ok
```
```elixir
iex(11)> produce(such_that {_x1, _x2, _x3, _x4, size} 
  <- Merkel.TreePropTest.generate_tree(:option_min_one_tree), when: size == 3)
{:ok,
 {#Merkel.Tree<{3,
   {"a28b2edeeb8e72881763e0ece89c257dc7a317e2bfcd53aefd48ed17059ddfda",
    "<=oE..>", 2,
    {"d890..", "<=7F..>", 1, {"e818..", "7FjDV", 0}, {"cf21..", "oEr", 0}},
    {"95df..", "tgSA 4Nz", 0}}}>,
  [
    {"oEr", -0.057744741577119},
    {"tgSA 4Nz", -6.749199934830595},
    {"7FjDV", :"5Ô\f\x96"}
  ], ["7FjDV", "oEr", "tgSA 4Nz"], "oEr", 3}}
```
