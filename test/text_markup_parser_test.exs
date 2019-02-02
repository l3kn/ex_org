defmodule ExOrg.TextMarkupParserTest do
  use ExUnit.Case
  doctest ExOrg.TextMarkupParser

  alias ExOrg.TextMarkupParser

  test "no emphasis" do
    assert TextMarkupParser.parse("foo") == "foo"
  end

  test "bold" do
    expected = {:emphasis, [type: :bold], "foo"}
    assert TextMarkupParser.parse("*foo*") == expected
  end

  test "italic" do
    expected = {:emphasis, [type: :italic], "foo"}
    assert TextMarkupParser.parse("/foo/") == expected
  end

  test "strike-through" do
    expected = {:emphasis, [type: :strikethrough], "foo"}
    assert TextMarkupParser.parse("+foo+") == expected
  end

  test "code" do
    expected = {:emphasis, [type: :code], "foo"}
    assert TextMarkupParser.parse("~foo~") == expected
  end

  test "verbatim" do
    expected = {:emphasis, [type: :verbatim], "foo"}
    assert TextMarkupParser.parse("=foo=") == expected
  end

  test "surrounded" do
    expected = [
      "foo ",
      {:emphasis, [type: :bold], "bar"},
      " baz",
    ]
    assert TextMarkupParser.parse("foo *bar* baz") == expected
  end

  test "multiple different" do
    expected = [
      "foo ",
      {:emphasis, [type: :verbatim], "bar"},
      " ",
      {:emphasis, [type: :bold], "baz"},
      " qux ",
      {:emphasis, [type: :italic], "quux"},
    ]
    assert TextMarkupParser.parse("foo =bar= *baz* qux /quux/") == expected
  end

  test "nested" do
    expected = [
      {:emphasis, [type: :bold], [
	  "foo ",
	  {:emphasis, [type: :italic], [
	      "bar ",
	      {:emphasis, [type: :strikethrough], "baz"},
	    ]},
	]},
      " qux",
    ]
    assert TextMarkupParser.parse("*foo /bar +baz+/* qux") == expected
  end

  test "nested code / verbatim" do
    expected = [
      {:emphasis, [type: :code], "foo +bar+"},
      " ",
      {:emphasis, [type: :verbatim], "*baz*"},
    ]
    assert TextMarkupParser.parse("~foo +bar+~ =*baz*=") == expected
  end

  test "multiline" do
    expected = {:emphasis, [type: :code], "foo\nbar\nbaz"}
    assert TextMarkupParser.parse("~foo\nbar\nbaz~") == expected
  end
end
