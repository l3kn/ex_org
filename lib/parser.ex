defmodule ExOrg.Parser do
  @moduledoc """
  After tokenizing the document,
  combine tokens into nodes
  """

  alias ExOrg.Lexer
  alias ExOrg.TextMarkupParser

  def lines(document) do
    document
    |> String.split(~r{\r?\n}, trim: true)
  end

  def parse_element([]) do
    nil
  end

  @doc """
  Parse input-lines until one element is complete,
  then return the element and the remaining lines
  """
  def parse_element([line | lines]) do
    token = Lexer.process_line(line)

    case token do
      {:header, opts, body} ->
        raise "Not implemented yet"

      {:line, _opts, text} ->
        {paragraph, lines} = parse_lines(lines, [text])
        {{:paragraph, paragraph}, lines}

      {:block_start, [indentation: _ind, name: "SRC"], params} ->
        {body, lines} = parse_src_block_body(lines, "SRC")
        {{:src_block, params, body}, lines}
    end
  end

  defp parse_src_block_body(lines, name, acc \\ [])

  defp parse_src_block_body([], name, acc) do
    raise "Unexpected end of input inside block body"
  end

  defp parse_src_block_body([line | lines], name, acc) do
    token = Lexer.process_line(line)

    case token do
      {:block_end, [indentation: _ind, name: ^name], nil} ->
        {join_paragraph(acc), lines}

      _ ->
        parse_src_block_body(lines, name, [line | acc])
    end
  end

  @doc """
  Parse input-lines while they tokenize to
  `:line`es.

  Return a tuple `{paragraph, remaining}`
  where `paragraph` is a bunch of lines
  joined with newlines.
  """
  defp parse_lines([], acc) do
    {join_paragraph(acc), []}
  end

  defp parse_lines([line | lines], acc) do
    token = Lexer.process_line(line)

    case token do
      {:line, _opts, text} ->
        parse_lines(lines, [text, acc])

      _ ->
        {join_paragraph(acc), [line | lines]}
    end
  end

  defp join_paragraph(para) do
    para
    |> Enum.reverse()
    |> Enum.join("\n")
  end
end
