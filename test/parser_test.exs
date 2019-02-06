defmodule ExOrg.ParserTest do
  use ExUnit.Case

  alias ExOrg.Parser

  test "paragraph parsing" do
    input = """
    foo
    bar baz
    1. list
    2. list
    """

    {{type, para}, rest} =
      input
      |> Parser.lines()
      |> Parser.parse_element()

    assert type == :paragraph
    assert para == "foo\nbar baz"
    assert rest == ["1. list", "2. list"]
  end

  test "source block parsing" do
    input = """
    #+BEGIN_SRC ruby
    tmp = a
    a = b
    b = b + tmp
    #+END_SRC
    1. list
    2. list
    """

    {{type, params, body}, rest} =
      input
      |> Parser.lines()
      |> Parser.parse_element()

    assert type == :src_block
    assert params == "ruby"
    assert body == "tmp = a\na = b\nb = b + tmp"
    assert rest == ["1. list", "2. list"]
  end

  # TODO: Test failure cases
end
