defmodule ExOrg.LexerTest do
  use ExUnit.Case

  alias ExOrg.Lexer

  test "headers" do
    input = """
    * Main
    ** Section 1
    **** Subsubsection
    """

    expected = [
      {:header, [level: 1], "Main"},
      {:header, [level: 2], "Section 1"},
      {:header, [level: 4], "Subsubsection"},
    ]

    assert Lexer.lex(input) == expected
  end

  test "unordered lists" do
    # List elements with `*` as a bullet must be preceeded by whitespace
    input = """
    + foo
      * bar
    1) baz
       2. qux
       a) quux
          b. what metasyntactic variable comes next?
    """
    lines = String.split(input, "\n", trim: true)

    expecteds = [
      {:unordered_list_element, [indentation: 0, bullet: "+"], "foo"},
      {:unordered_list_element, [indentation: 2, bullet: "*"], "bar"},
      {:unordered_list_element, [indentation: 0, bullet: "1)"], "baz"},
      {:unordered_list_element, [indentation: 3, bullet: "2."], "qux"},
      {:unordered_list_element, [indentation: 3, bullet: "a)"], "quux"},
      {:unordered_list_element, [indentation: 6, bullet: "b."], "what metasyntactic variable comes next?"},
    ]

    Enum.zip(lines, expecteds)
    |> Enum.each(fn {line, expected} ->
      assert Lexer.lex(line) == [expected]
    end)
  end

  test "blocks" do
    input = """
    #+BEGIN_SRC elixir
    #+END_SRC
    """
    lines = String.split(input, "\n", trim: true)

    expecteds = [
      {:block_start, [indentation: 0, name: "SRC"], "elixir"},
      {:block_end, [indentation: 0, name: "SRC"], nil},
    ]

    Enum.zip(lines, expecteds)
    |> Enum.each(fn {line, expected} ->
      assert Lexer.lex(line) == [expected]
    end)
  end
end
