require 'strscan'

module TeXTemplate

  def TeXTemplate.tikzpicture(s)
    s, libraries = TeXTemplate.extract_libraries(s)
    Boilerplate_start + "\n\\usetikzlibrary{#{libraries.join(',') unless libraries.empty?}}\n\\begin{document}\n\\begin{tikzpicture}#{s}\n\\end{tikzpicture}\\end{document}"
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
\\usepackage{amssymb}
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

% Widecheck
\\makeatletter
\\DeclareRobustCommand\\widecheck[1]{{\\mathpalette\\@widecheck{#1}}}
\\def\\@widecheck#1#2{%
    \\setbox\\z@\\hbox{\\m@th$#1#2$}%
    \\setbox\\tw@\\hbox{\\m@th$#1%
       \\widehat{%
          \\vrule\\@width\\z@\\@height\\ht\\z@
          \\vrule\\@height\\z@\\@width\\wd\\z@}$}%
    \\dp\\tw@-\\ht\\z@
    \\@tempdima\\ht\\z@ \\advance\\@tempdima2\\ht\\tw@ \\divide\\@tempdima\\thr@@
    \\setbox\\tw@\\hbox{%
       \\raise\\@tempdima\\hbox{\\scalebox{1}[-1]{\\lower\\@tempdima\\box
\\tw@}}}%
    {\\ooalign{\\box\\tw@ \\cr \\box\\z@}}}
\\makeatother

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
\\newcommand{\\Otimes}{\\bigotimes}
\\newcommand{\\Wedge}{\\bigwedge}
\\newcommand{\\Vee}{\\bigvee}
\\newcommand{\\coproduct}{\\coprod}
\\newcommand{\\product}{\\prod}
\\newcommand{\\closure}{\\overline}
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
      libraries << buffer[1].split(/\s*,\s*/)
    end
    return [out, libraries]
  end

end