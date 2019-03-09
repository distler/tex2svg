ENV['APP_ENV'] = 'test'

require_relative '../tex2svg'
require 'test/unit'
require 'rack/test'

class TeX2SVGTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    TeX2SVG
  end

  def test_empty_request
    get '/'
    assert last_response.ok?
    assert_equal '', last_response.body
  end

  def test_some_tex
    get '/', {:tex => "\\fill (0,0) circle[radius=2em];"}
    assert last_response.ok?
    assert last_response.body.include?('<g id="surface1">')
  end

  def test_some_tex_with_type
    get '/', {:tex => "\\fill (0,0) circle[radius=2em];", :type => 'tikzpicture'}
    assert last_response.ok?
    assert last_response.body.include?('<g id="surface1">')
  end

  def test_some_tex_with_other_type
    get '/', {:tex => "\\fill (0,0) circle[radius=2em];", :type => 'tikzcd'}
    assert last_response.ok?
    assert last_response.body.include?('<g id="surface1">')
  end

  def test_bad_tex
    get '/', {:tex => "\\end{matrix}", :type => 'tikzpicture'}
    assert last_response.ok?
    assert last_response.body.include?('No SVG file was generated')
  end

  def test_bad_tex_with_other_type
    get '/', {:tex => "\\end{matrix}", :type => 'tikzcd'}
    assert last_response.ok?
    assert last_response.body.include?("<g id=\"surface1\">\n</g>")
  end

  def test_overlong_submission
    overlong = 'a' * (TeX2SVG::max_length + 1)
    get '/', {:tex => overlong}
    assert last_response.ok?
    assert_equal "TeX fragment must be less than #{TeX2SVG::max_length} characters. Yours was #{TeX2SVG::max_length+1}.\n", last_response.body
  end

  def test_with_tikz_libraries
    trefoil = <<-TREND
    \\usetikzlibrary{decorations.markings}

    \\path (-2.5,-2.5) -- (-2.5,1.5) -- (3.5,1.5) -- (2.5,-2.5) -- (2.5,-2.5);

    \\draw[semithick, shorten <= 0.5em, shorten >= 0.5em] (2,0) -- (0,0) -- (0,-1) -- (1,-1);
    \\draw[semithick, shorten <= 0.5em, shorten >= 0.5em] (1,-1) -- (2,-1) -- (2,1) -- (1,1) -- (1,0);
    \\draw[semithick, shorten <= 0.5em, shorten >= 0.5em] (1,0) -- (1,-2) -- (3,-2) -- (3,0) -- (2,0);

    \\filldraw[black] (0,-0.5) circle (2pt);

    \\node[anchor=south] at (0.5,0) {$a$};
    \\node[anchor=north] at (1.6,-1) {$b$};
    \\node[anchor=east] at (1,-1.6) {$c$};

    \\node at (-0.25, -0.5) {$p$};

    \\path[decoration = { markings, mark=at position 0.5 with {\\arrow[scale=2]{>}}}, postaction = {decorate}] (2,-1) -- (2,0);
    \\path[decoration = { markings, mark=at position 0.5 with {\\arrow[scale=2]{>}}}, postaction = {decorate}] (2,1) -- (1,1);
    \\path[decoration = { markings, mark=at position 0.5 with {\\arrow[scale=2]{>}}}, postaction = {decorate}] (2,0) -- (1,0);
    \\path[decoration = { markings, mark=at position 0.5 with {\\arrow[scale=2]{>}}}, postaction = {decorate}] (1,-2) -- (3,-2);
    \\path[decoration = { markings, mark=at position 0.5 with {\\arrow[scale=2]{>}}}, postaction = {decorate}] (0,-1) -- (1,-1);
    \\path[decoration = { markings, mark=at position 0.5 with {\\arrow[scale=2]{>}}}, postaction = {decorate}] (3,-2) -- (3,0);
TREND
    get '/', {:tex => trefoil, :type => 'tikzpicture'}
    assert last_response.ok?
    assert last_response.body.include?('<g id="surface1">')
  end

  def test_tikzcd_with_tikz_libraries
    testcd = '\\usetikzlibrary{decorations.markings}
    \\ar[dd, dash,dashed,
             "\\text{something}" swap,
             to path={
                   -- ([xshift=-1.5cm]\\tikztostart.east)
                   |- (\\tikztotarget) [pos=0.25] \\tikztonodes
             }]
             L   
             \\ar[d, dash, dashed]  
             \\ar[d, dash, dashed] 
             \\\\
             E
             \\ar[d,dash,"<\\infty \\ \\  \\emph{separable}"] 
             \\\\
             F'
    get '/', {:tex => testcd, :type => 'tikzcd'}
    assert last_response.ok?
    assert last_response.body.include?('<g id="surface1">')
  end
end

