defmodule ExOrg.TextMarkupParser do
  @moduledoc """
  Sub-parser for text markup  

  Quoting from https://orgmode.org/worg/dev/org-syntax.html:
  
  Text markup follows the pattern
  `PRE MARKER CONTENTS MARKER POST`
  
  `PRE` is any whitespace character, `(`, `{`, `'` or a double quote.
  It can also be a beginning of line.
  
  TODO: I'm not sure how to handle the "beginning of line" part
  
  `MARKER` is a character among `*` (bold), `=` (verbatim), `/` (italic)
  `+` (strike-through), `_` (underline), `~` (code)
  
  `CONTENTS` is a string following the pattern `BORDER BODY BORDER`
  
  `BORDER` can be any non-whitespace character excepted `,`, `'` or a double quote.
  `BODY` can contain any character but may not span over more than 3 lines.

  `BORDER` and `BODY` are not separated by whitespace.
  
  `CONTENTS` can contain any object encountered in a paragraph
  when markup is "bold", "italic", "strike-through" or "underline".

  `POST` is a whitespace charatcer, `-`, `.`, `,`, `:`, `!`, `?`, `'`, `)`, `}`
  or a double quote. It can also be an end of line.

  `PRE`, `MARKER`, `CONTENTS`, `MARKER` and `POST` are not spearated by whitespace characters.
  
  Notes:

  The “may not span over more than 3 lines” restriction is not handled (yet)
  """
  @pre_re ~s{ \t\(\{'"}
  @post_re ~s{- \t.,:!?;\(\{'\"}
  @marker_re ~s{[\*\+=/_~]}
  @border_forbidden_re ~s{[^,'\" \t]}
  @newline ~s{\r?\n}
  @whitespace ~s{ |\t|\r?\n}
  @body_re ~s{[\\s\\S]*?}

  @emphasis_re ~r{([#{@pre_re}]|^|#{@newline})(#{@marker_re})(#{@border_forbidden_re}#{@body_re}#{@border_forbidden_re})(\2)([#{@post_re}]|$|#{@newline})}

  defp extract_before_capture(_text, {0, _}), do: ""
  defp extract_before_capture(text, {from, _}) do
    String.slice(text, 0..(from - 1))
  end

  defp extract_capture(text, {from, len}) do
    String.slice(text, from..(from + len - 1))
  end

  defp extract_after_capture(text, {from, len}) do
    String.slice(text, (from + len)..-1)
  end

  defp emphasis_type("*"), do: :bold
  defp emphasis_type("/"), do: :italic
  defp emphasis_type("+"), do: :strikethrough
  defp emphasis_type("="), do: :verbatim
  defp emphasis_type("~"), do: :code

  defp process_match(text, [_full, _pre, marker, body, _marker2, _post]) do
    type =
      text
      |> extract_capture(marker)
      |> emphasis_type()
    body = extract_capture(text, body)

    # Nested emphasis is not allowed inside verbatim or code blocks
    if type == :verbatim || type == :code do
      {:emphasis, [type: type], body}
    else
      {:emphasis, [type: type], parse(body)}
    end
  end

  defp promote_single([single]), do: single
  defp promote_single(multiple), do: multiple
  
  def parse(text, acc \\ [])
  def parse("", acc) do
    promote_single(acc)
  end
  def parse(text, acc) do
    match = Regex.run(@emphasis_re, text, return: :index)
    if match do
      [_full, _pre, marker, _body, marker2, _post] = match
      plain_before = extract_before_capture(text, marker)
      emphasis = process_match(text, match)
      rest = extract_after_capture(text, marker2)

      # Don't include empty "before" parts
      if plain_before == "" do
	parse(rest, acc ++ [emphasis])
      else
	parse(rest, acc ++ [plain_before, emphasis])
      end
    else
      promote_single(acc ++ [text])
    end
  end
end
