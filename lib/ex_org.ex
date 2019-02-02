defmodule ExOrg do
  @moduledoc """
  Parser of the org-mode markup language
  """

  @doc """
  Quoting from https://orgmode.org/worg/dev/org-syntax.html
  
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
  """
  @pre_re ~s{ \t\(\{'"}
  @post_re ~s{- \t.,:!?;\(\{'\"}
  @marker_re ~s{[\*\+=/_~]}
  @border_forbidden_re ~s{[^,'\" \t]}
  @newline ~s{\r?\n}
  @whitespace ~s{ |\t|\r?\n}
  @body_re ~s{[\\s\\S]*?}

  @emphasis_re ~r{([#{@pre_re}]|^|#{@newline})(#{@marker_re})(#{@border_forbidden_re}#{@body_re}#{@border_forbidden_re})\2([#{@post_re}]|$|#{@newline})}

  defp extract_capture(text, {from, to}) do
    String.slice(text, from..(from + to - 1))
  end

  defp process_match(text, [_full, pre, emph, body, post]) do
    {
      extract_capture(text, pre),
      extract_capture(text, emph),
      extract_capture(text, body),
      extract_capture(text, post),
    }
  end
  
  def match(text) do
    Regex.run(@emphasis_re, text, return: :index)
  end

  def match_full(text, acc \\ [])
  def match_full("", acc) do
    acc
  end
  def match_full(text, acc) do
    m = match(text)
    IO.inspect(m)
    case m do
      [{0, a2}, _, _, _, _] -> match_full(
	String.slice(text, a2..-1),
	acc ++ [
	  {:match, process_match(text, m)}
	] 
      )
      [{a1, a2}, _, _, _, _] -> match_full(
	String.slice(text, (a1+a2)..-1),
	acc ++ [
	  {:plain, String.slice(text, 0..(a1-1))},
	  {:match, process_match(text, m)}
	] 
      )
    nil -> acc ++ [{:plain, text}]
    end
  end
end

IO.inspect(ExOrg.match_full("*foo*"))
IO.inspect(ExOrg.match_full("foo *bar* baz +qux+"))
