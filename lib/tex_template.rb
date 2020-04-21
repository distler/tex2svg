require 'strscan'

module TeXTemplate

  def TeXTemplate.tikzpicture(s)
    s, libraries = TeXTemplate.extract_libraries(s)
    Boilerplate_start + "\n\\usetikzlibrary{#{libraries.push('arrows.meta').uniq.join(',')}}\n#{Arrows_start}\n\\begin{document}\n\\begin{tikzpicture}#{s}\n\\end{tikzpicture}\\end{document}"
  end

  def TeXTemplate.tikzcd(s)
    s, libraries = TeXTemplate.extract_libraries(s)
    Boilerplate_start + "\n\\usetikzlibrary{cd#{libraries.empty? ? '' : (',' + libraries.join(','))}}\n\\tikzcdset{arrow style=math font}\n\\begin{document}\n\\begin{tikzcd}#{s}\n\\end{tikzcd}\\end{document}"
  end

  Boilerplate_start = <<-BS
\\documentclass[12pt,crop,tikz]{standalone}
\\usepackage{stix2}
\\usepackage{amsmath}
\\usepackage{mathrsfs}
\\usepackage{amsfonts}
\\usepackage{amsthm}
\\usepackage{mathtools}
\\usepackage{color}
\\usepackage{ucs}
\\usepackage[utf8x]{inputenc}
\\usepackage{xparse}

%----Macros----------
%
% Unresolved issues:
%
%  \\righttoleftarrow
%  \\lefttorightarrow
%
%  \\color{} with HTML colorspec
%  \\bgcolor
%  \\array with options (without options, it's equivalent to the matrix environment)

% Of the standard HTML named colors, white, black, red, green, blue and yellow
% are predefined in the color package. Here are the rest.
\\definecolor{aqua}{rgb}{0, 1.0, 1.0}
\\definecolor{fuschia}{rgb}{1.0, 0, 1.0}
\\definecolor{gray}{rgb}{0.502, 0.502, 0.502}
\\definecolor{lime}{rgb}{0, 1.0, 0}
\\definecolor{maroon}{rgb}{0.502, 0, 0}
\\definecolor{navy}{rgb}{0, 0, 0.502}
\\definecolor{olive}{rgb}{0.502, 0.502, 0}
\\definecolor{purple}{rgb}{0.502, 0, 0.502}
\\definecolor{silver}{rgb}{0.753, 0.753, 0.753}
\\definecolor{teal}{rgb}{0, 0.502, 0.502}

% Because of conflicts, \\space and \\mathop are converted to
% \\itexspace and \\operatorname during preprocessing.

% itex: \\space{ht}{dp}{wd}
%
% Height and baseline depth measurements are in units of tenths of an ex while
% the width is measured in tenths of an em.
\\makeatletter
\\newdimen\\itex@wd%
\\newdimen\\itex@dp%
\\newdimen\\itex@thd%
\\def\\itexspace#1#2#3{\\itex@wd=#3em%
\\itex@wd=0.1\\itex@wd%
\\itex@dp=#2ex%
\\itex@dp=0.1\\itex@dp%
\\itex@thd=#1ex%
\\itex@thd=0.1\\itex@thd%
\\advance\\itex@thd\\the\\itex@dp%
\\makebox[\\the\\itex@wd]{\\rule[-\\the\\itex@dp]{0cm}{\\the\\itex@thd}}}
\\makeatother

% \\tensor and \\multiscript
\\makeatletter
\\newif\\if@sup
\\newtoks\\@sups
\\def\\append@sup#1{\\edef\\act{\\noexpand\\@sups={\\the\\@sups #1}}\\act}%
\\def\\reset@sup{\\@supfalse\\@sups={}}%
\\def\\mk@scripts#1#2{\\if #2/ \\if@sup ^{\\the\\@sups}\\fi \\else%
  \\ifx #1_ \\if@sup ^{\\the\\@sups}\\reset@sup \\fi {}_{#2}%
  \\else \\append@sup#2 \\@suptrue \\fi%
  \\expandafter\\mk@scripts\\fi}
\\def\\tensor#1#2{\\reset@sup#1\\mk@scripts#2_/}
\\def\\multiscripts#1#2#3{\\reset@sup{}\\mk@scripts#1_/#2%
  \\reset@sup\\mk@scripts#3_/}
\\makeatother

% \\slash
\\makeatletter
\\newbox\\slashbox \\setbox\\slashbox=\\hbox{$/$}
\\def\\itex@pslash#1{\\setbox\\@tempboxa=\\hbox{$#1$}
  \\@tempdima=0.5\\wd\\slashbox \\advance\\@tempdima 0.5\\wd\\@tempboxa
  \\copy\\slashbox \\kern-\\@tempdima \\box\\@tempboxa}
\\def\\slash{\\protect\\itex@pslash}
\\makeatother

% math-mode versions of \\rlap, etc
% from Alexander Perlis, "A complement to \\smash, \\llap, and lap"
%   http://math.arizona.edu/~aprl/publications/mathclap/
\\def\\clap#1{\\hbox to 0pt{\\hss#1\\hss}}
\\def\\mathllap{\\mathpalette\\mathllapinternal}
\\def\\mathrlap{\\mathpalette\\mathrlapinternal}
\\def\\mathclap{\\mathpalette\\mathclapinternal}
\\def\\mathllapinternal#1#2{\\llap{$\\mathsurround=0pt#1{#2}$}}
\\def\\mathrlapinternal#1#2{\\rlap{$\\mathsurround=0pt#1{#2}$}}
\\def\\mathclapinternal#1#2{\\clap{$\\mathsurround=0pt#1{#2}$}}

% Renames \\sqrt as \\oldsqrt and redefine root to result in \\sqrt[#1]{#2}
\\let\\oldroot\\root
\\def\\root#1#2{\\oldroot #1 \\of{#2}}
\\renewcommand{\\sqrt}[2][]{\\oldroot #1 \\of{#2}}

% \\mathraisebox{voffset}[height][depth]{something}
\\makeatletter
\\NewDocumentCommand\\mathraisebox{moom}{%
\\IfNoValueTF{#2}{\\def\\@temp##1##2{\\raisebox{#1}{$\\m@th##1##2$}}}{%
\\IfNoValueTF{#3}{\\def\\@temp##1##2{\\raisebox{#1}[#2]{$\\m@th##1##2$}}%
}{\\def\\@temp##1##2{\\raisebox{#1}[#2][#3]{$\\m@th##1##2$}}}}%
\\mathpalette\\@temp{#4}}
\\makeatletter

% udots (taken from yhmath)
\\makeatletter
\\def\\udots{\\mathinner{\\mkern2mu\\raise\\p@\\hbox{.}
\\mkern2mu\\raise4\\p@\\hbox{.}\\mkern1mu
\\raise7\\p@\\vbox{\\kern7\\p@\\hbox{.}}\\mkern1mu}}
\\makeatother

%% Fix array
\\newcommand{\\itexarray}[1]{\\begin{matrix}#1\\end{matrix}}
%% \\itexnum is a noop
\\newcommand{\\itexnum}[1]{#1}

%% Renaming existing commands
\\newcommand{\\neArrow}{\\Nearrow}
\\newcommand{\\neArr}{\\Nearrow}
\\newcommand{\\seArrow}{\\Searrow}
\\newcommand{\\seArr}{\\Searrow}
\\newcommand{\\nwArrow}{\\Nwarrow}
\\newcommand{\\nwArr}{\\Nwarrow}
\\newcommand{\\swArrow}{\\Swarrow}
\\newcommand{\\swArr}{\\Swarrow}
\\renewcommand{\\llangle}{\\lAngle}
\\renewcommand{\\rrangle}{\\rAngle}
\\newcommand{\\llbracket}{\\lBrack}
\\newcommand{\\rrbracket}{\\rBrack}
\\newcommand{\\Perp}{\\Vbar}
\\newcommand{\\invamp}{\\upand}
\\newcommand{\\parr}{\\upand}
\\newcommand{\\underoverset}[3]{\\underset{#1}{\\overset{#2}{#3}}}
\\newcommand{\\widevec}{\\overrightarrow}
\\newcommand{\\darr}{\\downarrow}
\\newcommand{\\nearr}{\\nearrow}
\\newcommand{\\nwarr}{\\nwarrow}
\\newcommand{\\searr}{\\searrow}
\\newcommand{\\swarr}{\\swarrow}
\\newcommand{\\curvearrowbotright}{\\curvearrowright}
\\newcommand{\\uparr}{\\uparrow}
\\newcommand{\\downuparrow}{\\updownarrow}
\\newcommand{\\duparr}{\\updownarrow}
\\newcommand{\\updarr}{\\updownarrow}
\\newcommand{\\gt}{>}
\\newcommand{\\lt}{<}
\\newcommand{\\map}{\\mapsto}
\\newcommand{\\embedsin}{\\hookrightarrow}
\\newcommand{\\Alpha}{A}
\\newcommand{\\Beta}{B}
\\newcommand{\\Zeta}{Z}
\\newcommand{\\Eta}{H}
\\newcommand{\\Iota}{I}
\\newcommand{\\Kappa}{K}
\\newcommand{\\Mu}{M}
\\newcommand{\\Nu}{N}
\\newcommand{\\Rho}{P}
\\newcommand{\\Tau}{T}
\\newcommand{\\Upsi}{\\Upsilon}
\\newcommand{\\omicron}{o}
\\newcommand{\\lang}{\\langle}
\\newcommand{\\rang}{\\rangle}
\\newcommand{\\Union}{\\bigcup}
\\newcommand{\\Intersection}{\\bigcap}
\\newcommand{\\Oplus}{\\bigoplus}
\\renewcommand{\\Otimes}{\\bigotimes}
\\renewcommand{\\Wedge}{\\bigwedge}
\\renewcommand{\\Vee}{\\bigvee}
\\newcommand{\\coproduct}{\\coprod}
\\newcommand{\\product}{\\prod}
\\renewcommand{\\closure}{\\overline}
\\newcommand{\\integral}{\\int}
\\newcommand{\\doubleintegral}{\\iint}
\\newcommand{\\tripleintegral}{\\iiint}
\\newcommand{\\quadrupleintegral}{\\iiiint}
\\newcommand{\\conint}{\\oint}
\\newcommand{\\contourintegral}{\\oint}
\\newcommand{\\infinity}{\\infty}
\\newcommand{\\bottom}{\\bot}
\\newcommand{\\minusb}{\\boxminus}
\\newcommand{\\plusb}{\\boxplus}
\\newcommand{\\timesb}{\\boxtimes}
\\newcommand{\\intersection}{\\cap}
\\newcommand{\\union}{\\cup}
\\newcommand{\\Del}{\\nabla}
\\newcommand{\\odash}{\\circleddash}
\\newcommand{\\negspace}{\\!}
\\newcommand{\\widebar}{\\overline}
\\newcommand{\\textsize}{\\normalsize}
\\renewcommand{\\scriptsize}{\\scriptstyle}
\\newcommand{\\scriptscriptsize}{\\scriptscriptstyle}
\\newcommand{\\mathfr}{\\mathfrak}
\\newcommand{\\statusline}[2]{#2}
\\newcommand{\\tooltip}[2]{#2}
\\newcommand{\\toggle}[2]{#2}
BS

# Use STIX Two arrows as the default arrow style in tikzpictures. Code to do this from
# https://tex.stackexchange.com/questions/396851/stix-arrow-tips-in-tikz-diagrams
  Arrows_start = <<-AS
%% Arrow declaration:
\\makeatletter
\\pgfdeclarearrow{
  name = stix,
  parameters = {\\ifpgfarrowharpoon h\\fi},
  setup code = {
    \\ifpgfarrowharpoon
      \\pgfutil@tempdima=\\dimexpr\\pgflinewidth/68
      \\pgfarrowssettipend{247\\pgfutil@tempdima}
      \\pgfarrowssetlineend{\\pgfutil@tempdima}
      \\pgfarrowssetbackend{-81\\pgfutil@tempdima}
      \\pgfarrowshullpoint{-81\\pgfutil@tempdima}{224\\pgfutil@tempdima}
      \\pgfarrowshullpoint{-58\\pgfutil@tempdima}{247\\pgfutil@tempdima}
      \\pgfarrowshullpoint{247\\pgfutil@tempdima}{-34\\pgfutil@tempdima}
      \\pgfarrowshullpoint{0pt}{-34\\pgfutil@tempdima}
    \\else\\ifpgfarrowreversed
      \\pgfutil@tempdima=\\dimexpr\\pgflinewidth/68
      \\pgfarrowssettipend{0pt}
      \\pgfarrowssetlineend{-\\pgfutil@tempdima}
      \\pgfarrowssetbackend{-208\\pgfutil@tempdima}
      \\pgfarrowsupperhullpoint{-208\\pgfutil@tempdima}{181\\pgfutil@tempdima}
      \\pgfarrowsupperhullpoint{-188\\pgfutil@tempdima}{201\\pgfutil@tempdima}
      \\pgfarrowsupperhullpoint{0pt}{34\\pgfutil@tempdima}
    \\else\\ifdim\\pgfinnerlinewidth>\\z@
      \\pgfutil@tempdima=\\dimexpr\\pgflinewidth/272
      \\pgfarrowssettipend{324\\pgfutil@tempdima}
      \\pgfarrowssetlineend{\\pgfutil@tempdima}
      \\pgfarrowssetbackend{-73\\pgfutil@tempdima}
      \\pgfarrowsupperhullpoint{-73\\pgfutil@tempdima}{285\\pgfutil@tempdima}
      \\pgfarrowsupperhullpoint{-51\\pgfutil@tempdima}{305\\pgfutil@tempdima}
      \\pgfarrowsupperhullpoint{324\\pgfutil@tempdima}{5\\pgfutil@tempdima}
    \\else
      \\pgfutil@tempdima=\\dimexpr\\pgflinewidth/68
      \\pgfarrowssettipend{192\\pgfutil@tempdima}
      \\pgfarrowssetlineend{\\pgfutil@tempdima}
      \\pgfarrowssetbackend{-72\\pgfutil@tempdima}
      \\pgfarrowsupperhullpoint{-72\\pgfutil@tempdima}{181\\pgfutil@tempdima}
      \\pgfarrowsupperhullpoint{-51\\pgfutil@tempdima}{201\\pgfutil@tempdima}
      \\pgfarrowsupperhullpoint{-192\\pgfutil@tempdima}{5\\pgfutil@tempdima}
    \\fi\\fi\\fi
  },
  drawing code = {
    \\ifpgfarrowharpoon %% harpoon
      \\pgftransformscale{\\pgflinewidth/68}
      \\pgfpathmoveto{\\pgfpoint{0}{34}}
      \\pgfpathcurveto{\\pgfpoint{40}{34}}{\\pgfpoint{44}{50}}{\\pgfpoint{44}{66}}
      \\pgfpathcurveto{\\pgfpoint{44}{94}}{\\pgfpoint{-22}{156}}{\\pgfpoint{-81}{224}}
      \\pgfpathlineto{\\pgfpoint{-58}{247}}
      \\pgfpathcurveto{\\pgfpoint{44}{147}}{\\pgfpoint{117}{66}}{\\pgfpoint{247}{-30}}
      \\pgfpathlineto{\\pgfpoint{247}{-34}}
      \\pgfpathlineto{\\pgfpoint{0}{-34}}
      \\pgfpathclose
      \\pgfusepathqfill
    \\else\\ifpgfarrowreversed %% reversed arrowhead
      \\pgftransformscale{\\pgflinewidth/68}
      \\pgfpathmoveto{\\pgfpoint{0}{34}}
      \\pgfpathcurveto{\\pgfpoint{-73}{78}}{\\pgfpoint{-134}{138}}{\\pgfpoint{-188}{201}}
      \\pgfpathlineto{\\pgfpoint{-208}{181}}
      \\pgfpathcurveto{\\pgfpoint{-185}{147}}{\\pgfpoint{-152}{118}}{\\pgfpoint{-124}{83}}
      \\pgfpathcurveto{\\pgfpoint{-111}{65}}{\\pgfpoint{-95}{33}}{\\pgfpoint{-95}{0}}
      \\pgfpathcurveto{\\pgfpoint{-95}{-33}}{\\pgfpoint{-111}{-65}}{\\pgfpoint{-124}{-83}}
      \\pgfpathcurveto{\\pgfpoint{-152}{-118}}{\\pgfpoint{-185}{-147}}{\\pgfpoint{-208}{-181}}
      \\pgfpathlineto{\\pgfpoint{-188}{-201}}
      \\pgfpathcurveto{\\pgfpoint{-134}{-138}}{\\pgfpoint{-73}{-78}}{\\pgfpoint{0}{-34}}
      \\pgfpathclose
      \\pgfusepathqfill
    \\else\\ifdim\\pgfinnerlinewidth>\\z@ %% double arrow
      \\pgftransformscale{\\pgflinewidth/272}
      \\pgfpathmoveto{\\pgfpoint{0}{136}}
      \\pgfpathcurveto{\\pgfpoint{18}{136}}{\\pgfpoint{27}{151}}{\\pgfpoint{27}{159}}
      \\pgfpathcurveto{\\pgfpoint{27}{175}}{\\pgfpoint{20}{184}}{\\pgfpoint{3}{202}}
      \\pgfpathcurveto{\\pgfpoint{-8}{213}}{\\pgfpoint{-48}{256}}{\\pgfpoint{-73}{285}}
      \\pgfpathlineto{\\pgfpoint{-51}{305}}
      \\pgfpathcurveto{\\pgfpoint{69}{187}}{\\pgfpoint{198}{100}}{\\pgfpoint{324}{5}}
      \\pgfpathlineto{\\pgfpoint{324}{-5}}
      \\pgfpathcurveto{\\pgfpoint{198}{-100}}{\\pgfpoint{69}{-187}}{\\pgfpoint{-51}{-305}}
      \\pgfpathlineto{\\pgfpoint{-73}{-285}}
      \\pgfpathcurveto{\\pgfpoint{-48}{-256}}{\\pgfpoint{-8}{-213}}{\\pgfpoint{3}{-202}}
      \\pgfpathcurveto{\\pgfpoint{20}{-184}}{\\pgfpoint{27}{-175}}{\\pgfpoint{27}{-159}}
      \\pgfpathcurveto{\\pgfpoint{27}{-151}}{\\pgfpoint{18}{-136}}{\\pgfpoint{0}{-136}}
      \\pgftransformreset
      \\pgfpathlineto{\\pgfpoint{0}{-.5*\\pgfinnerlinewidth}}
      \\pgftransformxshift{208\\pgflinewidth/272}
      \\pgftransformscale{\\pgfinnerlinewidth/136}
      \\pgfpathlineto{\\pgfpoint{-61}{-68}}
      \pgfpathcurveto{\\pgfpoint{-27}{-49}}{\\pgfpoint{0}{-24}}{\\pgfpoint{0}{0}}
      \\pgfpathcurveto{\\pgfpoint{0}{24}}{\\pgfpoint{-27}{49}}{\\pgfpoint{-61}{68}}
      \\pgftransformreset
      \\pgfpathlineto{\\pgfpoint{0}{.5*\\pgfinnerlinewidth}}
      \\pgfpathclose
      \\pgfusepathqfill
    \\else %% normal arrowhead
      \\pgftransformscale{\\pgflinewidth/68}
      \\pgfpathmoveto{\\pgfpoint{0}{34}}
      \\pgfpathcurveto{\\pgfpoint{18}{34}}{\\pgfpoint{26}{44}}{\\pgfpoint{26}{54}}
      \\pgfpathcurveto{\\pgfpoint{26}{63}}{\\pgfpoint{21}{74}}{\\pgfpoint{12}{83}}
      \\pgfpathcurveto{\\pgfpoint{-19}{115}}{\\pgfpoint{-48}{148}}{\\pgfpoint{-72}{181}}
      \\pgfpathlineto{\\pgfpoint{-51}{201}}
      \\pgfpathcurveto{\\pgfpoint{16}{123}}{\\pgfpoint{94}{47}}{\\pgfpoint{192}{5}}
      \\pgfpathlineto{\\pgfpoint{192}{-5}}
      \\pgfpathcurveto{\\pgfpoint{94}{-47}}{\\pgfpoint{16}{-123}}{\\pgfpoint{-51}{-201}}
      \\pgfpathlineto{\\pgfpoint{-72}{-181}}
      \\pgfpathcurveto{\\pgfpoint{-48}{-148}}{\\pgfpoint{-19}{-115}}{\\pgfpoint{12}{-83}}
      \\pgfpathcurveto{\\pgfpoint{21}{-74}}{\\pgfpoint{26}{-63}}{\\pgfpoint{26}{-54}}
      \\pgfpathcurveto{\\pgfpoint{26}{-44}}{\\pgfpoint{18}{-34}}{\\pgfpoint{0}{-34}}
      \\pgfpathclose
      \\pgfusepathqfill
    \\fi\\fi\\fi
  }
}
\\pgfdeclarearrow{
  name = stixhooks,
  parameters = {\\ifpgfarrowharpoon h\\fi},
  setup code = {
    \\pgfutil@tempdima=\\dimexpr\\pgflinewidth/68
    \\pgfarrowssettipend{184\\pgfutil@tempdima}
    \\pgfarrowssetlineend{\\pgfutil@tempdima}
    \\pgfarrowssetbackend{-79\\pgfutil@tempdima}
    \\pgfarrowsupperhullpoint{-79\\pgfutil@tempdima}{307\\pgfutil@tempdima}
    \\pgfarrowsupperhullpoint{184\\pgfutil@tempdima}{136\\pgfutil@tempdima}
    \\ifpgfarrowharpoon\\pgfarrowshullpoint{0pt}{-34\\pgfutil@tempdima}\\fi
  },
  drawing code = {
    \\pgftransformscale{\\pgflinewidth/68}
    \\ifpgfarrowharpoon\\else %% double-sided
      \\pgfpathmoveto{\\pgfpoint{0}{-34}}
      \\pgfpathcurveto{\\pgfpoint{61}{-34}}{\\pgfpoint{117}{-68}}{\\pgfpoint{117}{-135}}
      \\pgfpathcurveto{\\pgfpoint{117}{-197}}{\\pgfpoint{79}{-239}}{\\pgfpoint{18}{-239}}
      \\pgfpathlineto{\\pgfpoint{-79}{-239}}
      \\pgfpathlineto{\\pgfpoint{-79}{-307}}
      \\pgfpathlineto{\\pgfpoint{21}{-307}}
      \\pgfpathcurveto{\\pgfpoint{99}{-307}}{\\pgfpoint{184}{-245}}{\\pgfpoint{184}{-136}}
      \\pgfpathcurveto{\\pgfpoint{184}{-20}}{\\pgfpoint{80}{34}}{\\pgfpoint{0}{34}}
      \\pgfpathclose
      \\pgfusepathqfill
    \\fi
    \\pgfpathmoveto{\\pgfpoint{0}{34}}
    \\pgfpathcurveto{\\pgfpoint{61}{34}}{\\pgfpoint{117}{68}}{\\pgfpoint{117}{135}}
    \\pgfpathcurveto{\\pgfpoint{117}{197}}{\\pgfpoint{79}{239}}{\\pgfpoint{18}{239}}
    \\pgfpathlineto{\\pgfpoint{-79}{239}}
    \\pgfpathlineto{\\pgfpoint{-79}{307}}
    \\pgfpathlineto{\\pgfpoint{21}{307}}
    \\pgfpathcurveto{\\pgfpoint{99}{307}}{\\pgfpoint{184}{245}}{\\pgfpoint{184}{136}}
    \\pgfpathcurveto{\\pgfpoint{184}{20}}{\\pgfpoint{84}{-34}}{\\pgfpoint{4}{-34}}
    \\pgfpathclose
    \\pgfusepathqfill
  }
}
\\makeatother

%% STIX arrows have a line width of exactly 0.68em:
\\tikzset{every picture/.style={line width=.068em}}

%% Set up arrowheads:
\\tikzset{>=stix,
         |/.tip={Bar[width=.403em,line width=.052em]},
         lefthook/.tip={stixhooks[left]},
         righthook/.tip={stixhooks[right]},
         leftharpoon/.tip={>[left]},
         rightharpoon/.tip={>[right]}
}
AS

  def TeXTemplate.extract_libraries(s)
    buffer = StringScanner.new(s)
    libraries = []
    out = ''
    while ! buffer.eos?
      if buffer.scan(/(.*?)\\usetikzlibrary\{/)
        out << buffer[1]
      else
        out << buffer.rest
        return [out, libraries]
      end
      buffer.scan(/(.*?)\}/)
      libraries.concat buffer[1].split(/\s*,\s*/)
    end
    return [out, libraries]
  end

end