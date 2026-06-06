// --- CeTZ redraw of the proof_tree figure ---
// Only the "interesting" categories carry colour; Unrelated nodes are left
// empty so the eye lands on After / Active / Inflection.
#let _blue   = rgb("#f1f5f9")  // Unrelated → very pale slate (almost white, occludes edges)
#let _grey   = rgb("#a8a29e")  // After
#let _green  = rgb("#0d9488")  // Active (teal-600)
#let _orange = rgb("#f59e0b")  // Inflection (amber-500)
#let _stroke = rgb("#1e293b")  // slate-800 — fallback border / edges
// --------------------------------------------

#let AriComment(body) = text(fill: rgb("#F54927"))[*Ari Comment:* #body]
#let GrahamComment(body) = text(fill: rgb("#1122FF"))[*Graham Comment:* #body]
// commands.typ — paper-local macros translated from paper_commands.tex
// rv  — semantic marker for "this is a random variable / random sample"
// highlight kept as a back-compat alias for old call sites and visual highlights
#let rv(body) = text(fill: rgb("#E3158A"))[#body]
#let highlight(body) = rv(body)
#let Noise(body) = rv(body)

// ---------- General notation ----------
#let negl(n) = $sans("negl")(#n)$
#let PSpace = $\#sans("P")$
#let Complement(x) = $overline(#x)$
#let BigO(x) = $O(#x)$
#let BigOTilda(x) = $tilde(O)(#x)$
#let BigOmega(x) = $Omega(#x)$
#let SmallO(x) = $o(#x)$
#let bit = ${0,1}$
#let polyf(x) = $sans("poly")(#x)$
// samples: random-sampling operator. Renders as `<-$` — left arrow with a
// small pink `$` joined directly onto the arrow's tail (its right end), with
// no gap. Mimics the LaTeX \leftarrow\joinrel\smalldollar glyph.
#let samples = $arrow.l #h(-0.15em) #text(size: 0.7em, rv($\$$))$
#let iidSamples = highlight($attach(arrow.l, t: \$, br: sans("i.i.d"))$)
#let AdvA = $cal(A)$
#let oracle = $cal(O)$
#let SecurityParam = $kappa$
#let Naturals = $bb(N)$
#let Normalc = $cal(N)$
#let Integers = $bb(Z)$
#let Reals = $bb(R)$
#let Identity(x) = $bb(1)[#x]$
#let Expf(x) = $sans("exp")(#x)$
// Override Typst's builtin `exp` operator (which would render as the upright
// word "exp") so that exp(x) renders as e^x — matches \renewcommand{\exp}.
#let exp(x) = $e^(#x)$
#let Dist(x: none) = if x == none{$cal(D)$} else{$cal(D)(#x)$}
#let threshold = $phi$
#let Threshold = $tau$
#let Hierarchy = $cal(H)$

// ---------- Privacy parameters ----------
#let Episilon = $epsilon$
#let Eps = Episilon
#let ApproxParam = $Delta$
#let EstimationError = $gamma$
#let EpsDelta = $(Episilon, delta)$
#let Confidence = $eta$
#let Universe = $cal(U)$
#let Generalise = $sans("Generalise")$
#let KGeneralise(k) = $sans("Generalise")^((#k))$
#let GeneraliseMap(a, b) = $#a succ #b$
#let GeneraliseMapNot(a, b) = $#a cancel(succ) #b$
#let GeneraliseMapEq(a, b) = $#a succ.eq #b$
#let GeneraliseMapNotEq(a, b) = $#a cancel(succ.eq) #b$
#let argmax(..subs) = {
  let items = subs.pos()
  let sub = if items.len() == 1 {
    items.at(0)
  } else {
    math.mat(delim: none, row-gap: 0.35em, ..items.map(it => (it,)))
  }
  $op("arg max", limits: #true)_(#sub)$
}
#let Successors(p) = $sans("Succ")(#p)$
#let Parent(p) = $sans("Par")(#p)$
#let InflexionNode = $p^star$
#let InflexionLevel = $i^star$
#let pstar          = $p_(InflexionLevel(arrow(a)))$
#let Stream = $X$
#let dimsym = $d$
#let numInputs = $n$
#let clientInput(i) = $bold(arrow(x_(#i)))$
#let RelativeError(a, b) = $bar bar #a - #b bar - #a bar$
#let ExpectedRelativeError(a, b) = $bb(E)[bar bar #a - #b bar - #a bar]$

// ---------- Heavy hitters ----------
#let HH = $cal(H H)$
#let HHH(i) = $cal(H H H)_(#i)$
#let ApproxHHH(i) = $tilde(cal(H H H))_(#i)$
#let Output = $cal(S)$
#let frequency(p) = $f(#p)$
#let frequencyExpanded(p) = $f_(X)(#p)$
#let frequencyExpandedCustom(p, S) = $f_(#S)(#p)$
#let frequencyExpandedPrime(p) = $f_(X')(#p)$
#let frequencyApproxCustom(p, S) = $tilde(f)_(#S)(#p)$
#let frequencyApprox(p) = $tilde(f)_(X)(#p)$
#let frequencyApproxPrime(p) = $tilde(f)_(X')(#p)$
#let fMin(p) = $f_("min")(#p\; X)$
#let fMax(p) = $f_("max")(#p\; X)$

// ---------- Residuals ----------
#let Frequency(p) = $F_(X)(#p)$
#let Residual(p, S) = $F_(#S)(#p)$
#let ResidualX(p) = Residual(p, $cal(S)$)
#let ResidualXPrime(p) = Residual(p, $cal(S')$)
#let ApproxFrequencyCustom(p, S) = Residual(p, S)
#let NoisyResidualFrequencyCustom(p, S) = $tilde(F)_(#S)(#p)$
#let ApproxFrequencyCustomPrime(p, S) = $F'_(#S)(#p)$
#let ApproxFrequency(p) = Residual(p, $cal(S)$)
#let NoisyResidualFrequency(p) = $tilde(F)_(cal(S))(#p)$
#let ResidueSet(i) = $cal(R)_(#i)$
#let ResidueSetCustom(p, S) = $cal(R)_(#S)(#p)$
#let ApproxResidueSet(p) = $cal(R)_(cal(S))(#p)$

// ---------- DP and hierarchy ----------
#let GlobalSensitivity = $Delta_G$
#let Level(p) = $sans("Level")(#p)$
#let Tree = $cal(H)$
#let Algorithmf(name) = math.text(font: "DejaVu Sans Mono", name)
#let Setc(s) = $cal(#s)$
#let Mechanism = $sans(M)$
#let FuncDomain = $cal(H)$
#let FuncRange = $cal(Y)$
#let Laplace = $sans("Lap")$
#let Mean = $bb(E)$
// Partition and sub-partition sets used in the non-streaming privacy proof.
#let stop = $sans("END")$
#let Unrelated = $cal(I)_("Unrelated")$
#let OnPath    = $cal(I)_("Active")$
#let After     = $cal(I)_("After")$
#let far       = $cal(I)_("Far")$
#let almost    = $cal(I)_("Almost")$
#let ualmost    = $cal(I)_("Upper-Almost")$
#let special   = $cal(I)_("Special")$
#let PStar   = $cal(I)_("Inflex")$
#let MaxJ = highlight($j^*$)
#let SpaceSaving(i) = $sans("MG")_(#i)$
#let MG = $sans("MG")$
#let SpaceSavingPrivate(i) = $overline(sans("MG")_(#i))$
#let NumSketchCounter = $kappa$
#let MGParam = $kappa$
#let InsertSpaceSaving(x) = $sans("Insert")(#x)$
#let IncrementSS = $v$
#let Sketch = $cal(T)$
#let Counter = $C$
#let PowerSet(s) = $bb(P)(#s)$
#let Children(i, x) = $sans(c_(#i)[#x])$
#let ChildrenAll(x) = $sans(C[#x])$
#let MStream(x) = $sans(M)_(X)(#x)$
#let MStreamPrime(x) = $sans(M)_(X')(#x)$
#let Prob(e) = $Pr[#e]$
#let PProb(e, ..subs) = $Pr_(#subs.pos().map(s => $#s$).join(linebreak()))[#e]$
#let Size(e) = $|#e|$
#let outputSpecific(i) = $a(#i)$
#let outputAll = $arrow(a)$
#let MOut(i) = highlight($beta_(#i)$)
#let MOutPrime(i) = highlight($beta'_(#i)$)
#let MOutAll(i) = $arrow(beta)_(#i)$
#let MOutPrimeAll(i) = $arrow(beta)'_(#i)$
#let SizeOfUniverse = $m$
#let height = $h$
#let Height = $h$

// ---------- Section paragraph header ----------
#let para(title) = block(spacing: 0.6em)[#text(weight: "bold")[#title]]

// ---------- Drafting markers ----------
// `todo` — inline yellow tag for outstanding work.
// `comment` — inline red italic note for review remarks.
#let todo(body) = box(
  fill: rgb("#fef3c7"),
  inset: (x: 4pt, y: 2pt),
  radius: 2pt,
  text(fill: rgb("#92400e"), weight: "bold")[TODO: #body],
)
#let comment(body) = text(fill: rgb("#dc2626"), style: "italic")[[#body]]
