defmodule ExOrgTest do
  use ExUnit.Case
  doctest ExOrg

  test "no emphasis" do
    assert ExOrg.match_full("foo") == "foo"
  end

  test "bold" do
    expected = {:emphasis, [type: :bold], "foo"}
    assert ExOrg.match_full("*foo*") == expected
  end

  test "italic" do
    expected = {:emphasis, [type: :italic], "foo"}
    assert ExOrg.match_full("/foo/") == expected
  end

  test "strike-through" do
    expected = {:emphasis, [type: :strikethrough], "foo"}
    assert ExOrg.match_full("+foo+") == expected
  end

  test "code" do
    expected = {:emphasis, [type: :code], "foo"}
    assert ExOrg.match_full("~foo~") == expected
  end

  test "verbatim" do
    expected = {:emphasis, [type: :verbatim], "foo"}
    assert ExOrg.match_full("=foo=") == expected
  end

  test "surrounded" do
    expected = [
      "foo ",
      {:emphasis, [type: :bold], "bar"},
      " baz",
    ]
    assert ExOrg.match_full("foo *bar* baz") == expected
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
    assert ExOrg.match_full("foo =bar= *baz* qux /quux/") == expected
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
    assert ExOrg.match_full("*foo /bar +baz+/* qux") == expected
  end

  test "nested code / verbatim" do
    expected = [
      {:emphasis, [type: :code], "foo +bar+"},
      " ",
      {:emphasis, [type: :verbatim], "*baz*"},
    ]
    assert ExOrg.match_full("~foo +bar+~ =*baz*=") == expected
  end

  test "multiline" do
    expected = {:emphasis, [type: :code], "foo\nbar\nbaz"}
    assert ExOrg.match_full("~foo\nbar\nbaz~") == expected
  end
end
