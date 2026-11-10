ENV['APP_ENV'] = 'test'

require_relative '../tex2svg'
require 'test/unit'

class TestSanitizer < Test::Unit::TestCase

  def test_no_allowed
    [
      ["foo \\, ^^5cbar baz ^5cbop", "foo \\,  baz "],
      ["foo \\, ^^5Cbar", "foo \\, "],
      ["foo ^^5c, ^^5cbar", "foo \\, "],
      ["foo ^^5c, ^^5c* \\2 ^^5cbar2", "foo \\, * 2 2"],
      ["\\, ^^5cbar baz", "\\,  baz"],
      ["\\, ^^5cbar \\$ \\& \\% \\# baz", "\\,  \\$ \\& \\% \\# baz"],
      ["foo \\, \\bar baz", "foo \\,  baz"],
      ["foo \\, \\bar \\begin{bar}baz\\end{bar}", "foo \\,  baz"],
      ["foo \\, \\bar \\begin{bar\n}baz\\end{bar\n}", "foo \\,  baz"],
      ["foo \\, \\bar \\begin{bar}baz^^5cend{bar}", "foo \\,  baz"],
    ].each do |raw, cooked|
      s = TeXSanitizer.new(raw)
      assert_equal(cooked, s.sanitize)
    end
  end

  def test_bar_allowed
    [
      ["foo \\, ^^5cbar baz", "foo \\, \\bar baz"],
      ["foo \\, ^^5cbar", "foo \\, \\bar"],
      ["foo ^^5c, ^^5cbar", "foo \\, \\bar"],
      ["foo ^^5c, ^^5c* \\2 ^^5cbar2", "foo \\, * 2 \\bar2"],
      ["\\, ^^5cbar baz", "\\, \\bar baz"],
      ["\\, ^^5cbar \\$ \\& \\% \\# baz", "\\, \\bar \\$ \\& \\% \\# baz"],
      ["foo \\, \\bar baz", "foo \\, \\bar baz"],
      ["foo \\, \\bar \\begin{bar}baz\\end{bar}", "foo \\, \\bar baz"],
      ["foo \\, \\bar \\begin{bar\n}baz\\end{bar\n}", "foo \\, \\bar baz"],
      ["foo \\, \\bar \\begin{bar}baz^^5cend{bar}", "foo \\, \\bar baz"],
    ].each do |raw, cooked|
      s = TeXSanitizer.new(raw, Set['bar'])
      assert_equal(cooked, s.sanitize)
    end
  end

  def test_bar_environment_allowed
    [
      ["foo \\, ^^5cbar baz", "foo \\,  baz"],
      ["foo \\, ^^5cbar", "foo \\, "],
      ["foo ^^5c, ^^5cbar", "foo \\, "],
      ["foo ^^5c, ^^5c* \\2 ^^5cbar2", "foo \\, * 2 2"],
      ["\\, ^^5cbar baz", "\\,  baz"],
      ["\\, ^^5cbar \\$ \\& \\% \\# baz", "\\,  \\$ \\& \\% \\# baz"],
      ["foo \\, \\bar baz", "foo \\,  baz"],
      ["foo \\, \\bar \\begin{bar}baz\\end{bar}", "foo \\,  \\begin{bar}baz\\end{bar}"],
      ["foo \\, \\bar \\begin{bar\n}baz\\end{bar\n}", "foo \\,  baz"],
      ["foo \\, \\bar \\begin{bar}baz^^5cend{bar}", "foo \\,  \\begin{bar}baz\\end{bar}"],
    ].each do |raw, cooked|
      s = TeXSanitizer.new(raw, Set.new, Set['bar'])
      assert_equal(cooked, s.sanitize)
    end
  end

  def test_control_char_and_caret_preprocessing
    [
      # A newline before a disallowed sequence must not bypass sanitization.
      ["x\n\\input baz", "x\n baz"],
      # Runs of carets collapse to a single caret.
      ["a^^^^5c", "a"],
      # Control characters are removed.
      ["a\x00b", "ab"],
      # ^^ followed by 0x1C would otherwise be decoded to a backslash by TeX;
      # the control char is stripped and the carets collapse, so it cannot.
      ["^^\x1cinput{x}", "^input{x}"],
    ].each do |raw, cooked|
      assert_equal(cooked, TeXSanitizer.new(raw).sanitize)
    end
    # A newline no longer disrupts handling of an allowed sequence that follows.
    assert_equal("a\n\\bar baz", TeXSanitizer.new("a\n\\bar baz", Set['bar']).sanitize)
    assert_equal("a\\bar", TeXSanitizer.new("a\x00\\bar", Set['bar']).sanitize)
  end

  # Invalid UTF-8 must be scrubbed rather than raising out of gsub.
  def test_invalid_utf8_does_not_raise
    assert_nothing_raised do
      TeXSanitizer.new("\xff\xfe\\bar".dup.force_encoding('UTF-8')).sanitize
    end
  end

  # extract_libraries pulls \usetikzlibrary{...} out of the fragment. Both of
  # its scans use /m, so a \usetikzlibrary appearing after a line break is still
  # found and a library list wrapped across several lines is parsed rather than
  # dropping the whole picture. An unclosed brace is handled gracefully.
  def test_extract_libraries
    [
      # [input, expected libraries, expected remaining fragment]
      ["\\usetikzlibrary{calc,arrows}\\draw (0,0);",
       ["calc", "arrows"], "\\draw (0,0);"],
      ["\\usetikzlibrary{arrows.meta,\n  calc,\n  positioning}\\draw (0,0)--(1,1);",
       ["arrows.meta", "calc", "positioning"], "\\draw (0,0)--(1,1);"],
      ["some text\nmore text\n\\usetikzlibrary{calc}\\draw (0,0);",
       ["calc"], "some text\nmore text\n\\draw (0,0);"],
      ["\\usetikzlibrary{calc}\ntext\n\\usetikzlibrary{arrows.meta}\\draw (0,0);",
       ["calc", "arrows.meta"], "\ntext\n\\draw (0,0);"],
      ["\\draw (0,0)--(1,1);",
       [], "\\draw (0,0)--(1,1);"],
      # Unclosed \usetikzlibrary{ : drop the malformed fragment, do not raise.
      ["\\usetikzlibrary{arrows \\draw (0,0)--(1,1);",
       [], ""],
    ].each do |raw, libraries, remaining|
      out, libs = TeXTemplate.extract_libraries(raw)
      assert_equal(libraries, libs)
      assert_equal(remaining, out)
    end
  end

end