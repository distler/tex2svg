require 'strscan'
require 'set'

class TeXSanitizer

  def initialize(str, allowed_control_sequences = Set.new, allowed_environments = Set.new)
    @buffer = StringScanner.new(str)
    @out = String.new
    @allowed_control_sequences = allowed_control_sequences
    @allowed_environments = allowed_environments
  end

  def sanitize
    while ! @buffer.eos?
      if @buffer.scan(/(.*?)(\\|\^\^5c)/)
        @out << @buffer[1]
      else
        @out << @buffer.rest
        return @out
      end
      next_char = @buffer.scan(/(\\|\^\^5c| |,|:|;|!|\||\{|\}|\[|\]|\$|&|%|#)/)
      if next_char
        if next_char == '^^5c'
          @out << "\\\\"
        else
          @out << "\\#{next_char}"
        end
      else
        c = @buffer.scan(/[a-zA-Z]*/)
        case c
        when 'begin', 'end'
          break unless @buffer.skip(/\{/)
          @buffer.scan(/(.*?)(\}|\^\^7d)/m)
          environment = @buffer[1]
          @out << "\\#{c}\{#{environment}\}" if (@allowed_environments.include?(environment))
        else
          @out << "\\#{c}"  if (@allowed_control_sequences.include?(c))
        end
      end
    end
    return @out
  end

  Itex_control_sequences = Set.new %w[array arrayopts collayout colalign rowalign align equalcols equalrows collines
    rowlines frame padding rowopts cellopts rowspan colspan alpha beta gamma delta epsilon backepsilon varepsilon zeta
    eta theta vartheta iota kappa varkappa lambda mu nu xi omicron pi varpi rho varrho sigma varsigma tau upsilon phi
    varphi chi psi omega Alpha Beta Gamma Delta Zeta Eta Theta Iota Kappa Lambda Mu Nu Xi Pi Rho Sigma Tau Upsilon Upsi
    Phi Psi Omega digamma mho arccos arcsin arctan arg cos cosh cot coth csc deg det dim exp gcd inf hom ker lg lim
    liminf limsup ln log max min mod pmod Pr sec sin sinh sup tan tanh rightarrow to longrightarrow Rightarrow implies
    hookrightarrow embedsin mapsto map leftarrow longleftarrow Leftarrow impliedby hookleftarrow leftrightarrow
    Leftrightarrow Longleftrightarrow iff nearrow nearr nwarrow nwarr searrow searr swarrow swarr neArrow neArr nwArrow
    nwArr seArrow seArr swArrow swArr darr Downarrow uparr Uparrow downuparrow duparr updarr Updownarrow leftsquigarrow
    rightsquigarrow leftrightsquigarrow upuparrows rightleftarrows rightrightarrows dashleftarrow dashrightarrow
    curvearrowleft curvearrowbotright downdownarrows leftleftarrows leftrightarrows righttoleftarrow lefttorightarrow
    circlearrowleft circlearrowright curvearrowright leftarrowtail rightarrowtail leftrightsquigarrow Lleftarrow
    Rrightarrow looparrowleft looparrowright Lsh Rsh twoheadleftarrow twoheadrightarrow nLeftarrow nleftarrow
    nLeftrightarrow nleftrightarrow nRightarrow nrightarrow leftharpoonup leftharpoondown rightharpoonup rightharpoondown
    downharpoonleft downharpoonright leftrightharpoons rightleftharpoons upharpoonleft upharpoonright xrightarrow
    xleftarrow xleftrightarrow xLeftarrow xRightarrow xLeftrightarrow xleftrightharpoons xrightleftharpoons
    xhookleftarrow xhookrightarrow xmapsto langle lang rangle rang llangle rrangle lbrace rbrace lceil rceil lmoustache
    rmoustache lfloor rfloor lvert rvert lVert rVert llbracket rrbracket uparrow downarrow updownarrow vert Vert left right
    big Big bigg Bigg bigl Bigl biggl Biggl bigr Bigr biggr Biggr amalg angle measuredangle sphericalangle approx approxeq
    thickapprox ast asymp backslash because between bottom bot boxminus minusb boxplus plusb boxtimes timesb boxdot bowtie
    bullet cap intersection cup union Cap Cup cdot circledast circledcirc clubsuit curlyvee curlywedge diamondsuit
    divideontimes dotplus heartsuit spadesuit circ bigcirc cong ncong dagger ddagger dashv Vdash vDash nvDash VDash
    nVDash vdash nvdash Vvdash Diamond diamond div equiv nequiv eqcirc neq ne Bumpeq bumpeq circeq doteq doteqdot
    fallingdotseq risingdotseq exists nexists flat forall frown smallfrown gt ngtr gg ggg geq ge ngeq geqq ngeqq geqslant
    ngeqslant eqslantgtr gneq gneqq gnapprox gnsim gtrapprox gtrsim gtrdot gtreqless gtreqqless gtrless gvertneqq in notin
    ni notni intercal invamp parr lhd unlhd leftthreetimes rightthreetimes lt nless ll lll leq le nleq leqq nleqq leqslant
    nleqslant eqslantless lessapprox lessdot lesseqgtr lesseqqgtr lessgtr lesssim lnapprox lneq lneqq lnsim ltimes lvertneqq
    lozenge blacklozenge mid shortmid nmid nshortmid models multimap nabla Del natural not neg odot odash circleddash otimes
    oplus ominus oslash parallel nparallel shortparallel nshortparallel partial Perp Vbar perp pitchfork pm mp prec nprec
    precapprox precnapprox preceq npreceq preccurlyeq curlyeqprec precsim precnsim prime backprime propto varpropto rhd
    unrhd rtimes setminus smallsetminus sharp sim nsim backsim simeq backsimeq thicksim smile smallsmile sslash subset
    nsubset subseteq nsubseteq subseteqq nsubseteqq subsetneq subsetneqq varsubsetneq varsubsetneqq Subset succ nsucc
    succeq nsucceq succapprox succnapprox succcurlyeq curlyeqsucc succsim succnsim supset nsupset supseteq nsupseteq
    supseteqq supsetneq supsetneqq varsupsetneq varsupsetneqq Supset square Box blacksquare qed sqcup sqcap sqsubset
    sqsubseteq sqsupset sqsupseteq star bigstar therefore times top triangle triangledown triangleleft triangleright
    blacktriangle blacktriangledown bigtriangleup bigtriangledown blacktriangleleft blacktriangleright ntriangleleft
    ntriangleright ntrianglelefteq ntrianglerighteq trianglelefteq trianglerighteq triangleq vartriangleleft vartriangleright
    uplus vee veebar wedge barwedge doublebarwedge wr coloneqq Coloneqq coloneq Coloneq eqqcolon Eqqcolon eqcolon Eqcolon
    colonapprox Colonapprox colonsim Colonsim dblcolon aleph beth ell hbar Im imath jmath eth Re wp infty infinity emptyset
    varnothing dots ldots cdots ddots udots vdots colon bigcup Union bigcap Intersection bigodot bigoplus Oplus bigotimes
    Otimes bigsqcup bigsqcap biginterleave biguplus bigwedge Wedge bigvee Vee coprod coproduct prod product sum int
    integral iint doubleintegral iiint tripleintegral iiiint quadrupleintegral oint conint contourintegral displaystyle
    textstyle textsize scriptsize scriptscriptsize mathit mathbf boldsymbol mathrm mathbb mathfrak mathfr mathcal mathscr
    mathsf mathtt text thinspace medspace thickspace quad qquad negthinspace negmedspace negthickspace phantom mathrlap
    mathllap mathclap space bar overline closure widebar underline vec widevecoverrightarrow overleftarrow overleftrightarrow
    underrightarrow underleftarrow underleftrightarrow dot ddot dddot ddddot tilde widetilde check widecheck hat widehat
    slash boxed frac tfrac binom tbinom over atop substack overbrace underbrace underset overset stackrel underoverset
    tensor multiscripts sqrt root operatorname mathop mathbin mathrel mathraisebox itexnum color bgcolor label]
  Itex_environments = Set.new %w[matrix pmatrix bmatrix Bmatrix vmatrix Vmatrix smallmatrix cases aligned gathered split array]
  Tikz_environments = Set.new %w[scope pgfonlayer]
  Tikzpicture_control_sequences = Set.new %w[usetikzlibrary ar arrow clip coordinate draw fill filldraw graph matrix
    node path shade shadedraw useasboundingbox]
  Tikzcd_control_sequences = Set.new %w[usetikzlibrary ar arrow dar drar lar rar uar tikzcdset tikztonodes tikztotarget tikztostart]
end
