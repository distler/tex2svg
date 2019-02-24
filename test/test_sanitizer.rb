ENV['APP_ENV'] = 'test'

require_relative '../tex2svg'
require 'test/unit'

class TestSanitizer < Test::Unit::TestCase

  def test_no_allowed
    [
      ["foo \\, ^^5cbar baz", "foo \\,  baz"],
      ["foo \\, ^^5cbar", "foo \\, "],
      ["foo ^^5c, ^^5cbar", "foo \\, "],
      ["\\, ^^5cbar baz", "\\,  baz"],
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
      ["\\, ^^5cbar baz", "\\, \\bar baz"],
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
      ["\\, ^^5cbar baz", "\\,  baz"],
      ["foo \\, \\bar baz", "foo \\,  baz"],
      ["foo \\, \\bar \\begin{bar}baz\\end{bar}", "foo \\,  \\begin{bar}baz\\end{bar}"],
      ["foo \\, \\bar \\begin{bar\n}baz\\end{bar\n}", "foo \\,  baz"],
      ["foo \\, \\bar \\begin{bar}baz^^5cend{bar}", "foo \\,  \\begin{bar}baz\\end{bar}"],
    ].each do |raw, cooked|
      s = TeXSanitizer.new(raw, Set.new, Set['bar'])
      assert_equal(cooked, s.sanitize)
    end
  end

end