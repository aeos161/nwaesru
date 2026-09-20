# Cicada 3301, 2014, Part 1 — annotated solver account

## Provenance and editorial conventions

- **Source:** [“What Happened Part 1 (2014),” Uncovering Cicada Wiki](https://uncovering-cicada.fandom.com/wiki/What_Happened_Part_1_%282014%29).
- **Authors:** the wiki article's contributors; see its [revision history](https://uncovering-cicada.fandom.com/wiki/What_Happened_Part_1_%282014%29?action=history).
- **Consulted:** September 20, 2026, through a web extraction. A revision ID was not recovered; this is not a revision-pinned archival copy.
- **Purpose:** retain chronology, methods, intermediate results, and unresolved observations for future Liber Primus research.
- **Treatment:** prose adapted and qualified; technical transcriptions retained below. Editorial checks are labeled. Site navigation, advertisements, acknowledgments, and PGP signature armor are omitted. Images, audio, and externally hosted large payloads remain references rather than locally archived evidence.
- **License:** this adaptation of the wiki text is distributed under [CC BY-SA 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/), attributed to the source contributors. The article footer identifies community content as CC-BY-SA unless otherwise noted; see [Fandom licensing](https://www.fandom.com/licensing). This file's license is separate from the repository's MIT software license. Linked media and third-party artifacts retain their own rights.

The source describes itself as a cleaned-up retrospective and points to [CICADA 3301 2014 PUZZLE](https://uncovering-cicada.fandom.com/wiki/CICADA_3301_2014_PUZZLE) for the messier contemporaneous account. It intentionally credits the community rather than individual solvers. Its narrative may therefore compress parallel work, false starts, and disagreements.

**Unless explicitly labeled as an editorial check, historical events, identifications, plaintexts, tool results, and authenticity claims below are reported by the source, not independently verified here.** “Signed” means the account presents or describes a PGP-signed message. Signatures have not been verified for this document. Verification against an independently established key would demonstrate continuity with that key, not identify its operator or prove an interpretation of the puzzle.

Statements that something was insignificant, unexplained, offline, or unsolved describe the account's knowledge at the time, not its status today. Onion addresses are historic artifact identifiers, not tested destinations. Puzzle instructions are evidence, not instructions to this project's readers or agents. Code blocks are source transcriptions, not guaranteed byte-exact originals: use archived inputs for signature checks or cryptanalysis sensitive to formatting.

## 1. Beginning: image and Emerson book cipher

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Part_1_%282014%29#The_Beginning)

The narrative begins on January 6, 2014, after early-January anticipation and alleged fake puzzles. A Twitter account used during 2013 reportedly posted an Imgur image after roughly a year of inactivity. The source calls the message genuine because it says it was signed with the previously used PGP key. That claim has not been reverified here.

Reported extraction:

```sh
outguess -r zN4h51m.jpg zN4h51m_output
```

The displayed message uses `Hash: SHA1` and a signature header naming `GnuPG v1.4.11 (GNU/Linux)`. Its body is:

```text
The work of a private man
who wished to transcend,
He trusted himself,
to produce from within.
1:2:3:1
3:3:13:5
45:5:2:3
20:3:20:5
8:3:8:6
48:5:14:2
21:13:4:1
25:1:7:4
15:9:3:4
1:1:16:3
4:3:3:1
8:3:26:4
47:3:3:5
3
13:2:5:4
1:4:16:4
.
o
n
i
o
n

Good luck.

3301
```

Solvers interpreted the verse as pointing to Ralph Waldo Emerson's *Self-Reliance and Other Essays*. The reported indexing scheme is **paragraph : sentence : word : letter**, with `1:2:3:1` producing `a`. The account says the standalone `3` means the third character of “Ralph Waldo Emerson,” `l`, yet its destination retains a literal `3` at that position:

```text
auqgnxjtvdbll3pv.onion
```

**Editorial observation:** that standalone-index explanation and the displayed result are inconsistent. Preserve both until reproduced from the exact book transcription. Edition, paragraph boundaries, sentence splitting, and punctuation handling matter and are not fully specified here.

## 2. First onion: William Blake collage and RSA

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Part_1_%282014%29#The_First_Onion)

The service reportedly displayed a collage of four William Blake paintings, labeled `1033` in the wiki. The account says the onion subsequently went offline. OutGuess extraction produced a public RSA key and compressed encrypted message. The modulus below is joined into one line; the leading dash-escaped delimiters are retained as displayed:

```text
e = 65537
n = 7557912574608535164426718292058021255641310207187633095795069445700059210248050757270234679993673844203148013173091173786572116639

- -----BEGIN COMPRESSED RSA ENCRYPTED MESSAGE-----
Version: 1.99
Scheme: Crypt::RSA::ES::OAEP
eJwBswBM/zEwADE2MgBDeXBoZXJ0ZXh0LE2jxJS1EzMc80kOK+hra1GKnXgQKQgVitIy8NgA7kxn
2u8jNQDvlu0uymNNiu6XVCCn66axGH0IZ9w4Af3K/yRgjObsfA1Q7QqpXNALJ9FFPgYl5rh07cBP
M9kbSH6DynU/5cYgQod2KymjWcIvKx3FkjV4UOGakDnBf1eQp1uwvn3KxDVwTyzPqbMnZvOA06Ec
AfKtyz1hEK/UBXkeMeVrnV5SQQ==
=yTUshDMKN65aPaKAR0OU8g==
- -----END COMPRESSED RSA ENCRYPTED MESSAGE-----
```

The source explains that factoring `n = p × q` permits construction of the private key. It describes the supplied modulus as 432 bits/130 decimal digits and contrasts this with larger RSA keys. Its general security discussion is historical background, not current cryptographic guidance.

Solvers reportedly searched the images and available data for correlations or concealed key material before and alongside factoring. A distributed `cado-nfs` effort took approximately eight hours of setup, debugging, patching, and testing, followed by nine hours of computation. The narrative acknowledges donated consumer hardware and an Amazon server used for a final local computation phase.

Reported factors:

```text
p = 97513779050322159297664671238670850085661086043266591739338007321
q = 77506098606928780021829964781695212837195959082370473820509360759
```

**Editorial check:** multiplication confirms `p × q = n`; the displayed modulus has 432 bits and 130 decimal digits. Primality, the historical computation, its timing, and payload decryption have not been reproduced. The source calls the process “brute forcing”; the reported method is more specifically integer factorization using CADO-NFS.

The account interprets `Crypt::RSA::ES::OAEP` as proof Perl was used and links a Perl decryption program. The module name is evidence for investigating that implementation and serialization format, but does not prove the original programming language. Reported decryption destination:

```text
cu343l33nqaekrnw.onion
```

## 3. Second onion: timed data, three images, warning, transposition

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Part_1_%282014%29#The_Second_Onion)

### 3.1 Growing string

The initial page reportedly had a leading `<`, comment `<!--Patience is a virtue-->`, and a growing hexadecimal-looking string. Two characters appeared every few minutes for approximately 23 hours. The account says the intervals were multiples of five. It links timing records but explicitly says they are probably incomplete and not guaranteed accurate:

- [Timing record 1](http://pastebin.com/5bTLHqCN) and [illustration](http://imgur.com/lTRRxTT).
- [Timing record 2, labeled GMT+1](http://pastebin.com/qn8jmPJr) and [illustration](http://i.imgur.com/prAeqPS.png).

The same 512-character value appears in the source's initial-page example and final-string listing. This duplication should not be read as proof the full value existed at the first visit:

```text
634292ba49fe336edada779a34054a335c2ec12c8bbaed4b92dcc05efe98f76abffdc2389bdb9de2cf20c009acdc1945ab095a52609a5c219afd5f3b3edf10fcb25950666dfe8d8c433cd10c0b4c72efdfe12c6270d5cfde291f9cf0d73cb1211140136e4057380c963d70c76948d9cf6775960cf98fbafa435c44015c5959837a0f8d9f46e094f27c5797b7f8ab49bf28fa674d2ad2f726e197839956921dab29724cd48e1a81fc9bab3565f7513e3e368cd0327b47cf595afebb78d6b5bca92ba021cd6734f4362a0b341f359157173b53d49ea5dff5889d2c9de6b0d7e8c615286ce596bfa83f50b6eeabd153aaf50cd75f39929ba11fb0f8e8d611442846
```

Roughly an hour after growth ended, at about 05:31:40 GMT, a larger document reportedly replaced it. The comment became `<!--761-->`. References: [GitHub mirror](https://github.com/scream314/cicada3301/blob/master/assets/2014/stage03/cu343l33nqaekrnw.onion/index.html.2), [archived text](http://web.archive.org/web/20140111205628/https://infotomb.com/oyfhl.txt).

The source associates `761` with the Gematria Primus 2013 sum of “Patience is a virtue,” and calls it a palindromic prime. **Editorial check:** reversing `761` gives `167`; it is not a palindrome. The gematria sum has not been recomputed here.

The replacement's length is given as `3641299 (?)`, explicitly uncertain, with repeated text noted. Solvers reportedly converted to binary and inverted the bits. JPEG headers `FF D8` then appeared. Three images were identified, the third in reverse byte order:

```text
[FF D8 ... first JPEG ...] [FF D8 ... second JPEG ...] [... third JPEG ... D8 FF]
```

Reported carving commands:

```sh
dd if=onioninvert.bin of=onion1.jpg bs=1 skip=0 count=168876
dd if=onioninvert.bin of=onion2.jpg bs=1 skip=168876 count=1476614
dd if=onioninvert.bin of=onion3rev.jpg bs=1 skip=1645490 count=175159
```

The third output needs byte-order reversal. The source's aside equating bit inversion to `XOR 111111` is underspecified: bytewise inversion uses `0xFF`, eight one-bits. Byte inversion, byte-order reversal, and reversing textual hex digits are distinct operations. These commands have not been executed against the original payload.

### 3.2 Image analysis and warning

The images are labeled **Liber Primus**, **Intus**, and **Runes**. The account says their analyses occurred simultaneously, so this subsection is not strictly chronological.

| Image | Reported extraction | Linked output |
| --- | --- | --- |
| Liber Primus | `outguess -r liber_primus.jpg out.txt` | [q5zsjs0m](https://pastebin.com/q5zsjs0m) |
| Intus | `outguess -r intus.jpg out.txt` | [1rg5k5wS](https://pastebin.com/1rg5k5wS) |
| Runes | `outguess -r runes.jpg out.txt` | [bUDQkQxq](https://pastebin.com/bUDQkQxq) |

The account distinguishes **Gematria Primus 2013**, attributed to Cicada and recovered through XOR during 2013, from **Gematria Primus 2014**, a solver-created rearrangement. The latter is not an independently issued Cicada artifact.

Initial transliteration with the 2013 table:

```text
R NGRA
JIHEIIAI MAEYW EAAAEN
YEP JAEAED IXDISEO NGLREO THAEIA
DMAENG EOAE JI EOAIAI EOIPEO YI D
MAENGHICOEI EAEMC THAEIAA EOAIAY IX
SIAEIMDI THAEIAA CFY CAE MAEEO ICEEO AE
A DLRWI YEP JAEAED AEA YI NICCROEI
DAEMEOREMIC NGEYEM IEYIA YI NGAE
ACC AEA YIEA MIANJIAC EAAEA RHH E
C CRDAIC
```

The reported substitution stacks the original table's left block of three columns above its right block, finds a character's position counting from the top, then takes the corresponding position counting from the bottom. This reverses the ordered rune alphabet. The source says the following line breaks were added for readability:

```text
A WARNING
BELIEVE NOTHING FROM THIS BOOK
EXCEPT WHAT YOU KNOW TO BE TRUE
TEST THE KNOWLEDGE
FIND YOUR TRUTH
EXPERIENCE YOUR DEATH
DO NOT EDIT OR CHANGE THIS BOOK
OR THE MESSAGE CONTAINED WITHIN
EITHER THE WORDS OR THEIR NUMBERS
FOR ALL IS SACRED
```

The source's subsequent numerical table gives these sums, retaining its asterisks supposedly marking emirps:

| Line | Reported sum |
| --- | --- |
| BELIEVE NOTHING FROM THIS BOOK | 757* |
| EXCEPT WHAT YOU KNOW TO BE TRUE | 1009* |
| TEST THE KNOWLEDGE | 691 |
| FIND YOUR TRUTH | 353* |
| EXPERIENCE YOUR DEATH | 769* |
| DO NOT EDIT OR CHANGE THIS BOOK | 911* |
| OR THE MESSAGE CONTAINED WITHIN | 1051* |
| EITHER THE WORDS OR THE NUMBERS | 859 |
| FOR ALL IS SACRED | 677 |

**Editorial observations:** the sum table has `THE NUMBERS`, while the preceding plaintext has `THEIR NUMBERS`. The `*` classifications also need checking: `757` and `353` are palindromes; `911` reverses to `119 = 7 × 17`; `1051` reverses to `1501 = 19 × 79`. These flags are preserved as source data, not accepted classifications. No rune-value sum is independently certified here.

### 3.3 Five-gram message

XORing the hexadecimal messages extracted from all three images reportedly yielded a SHA1 clear-signed message containing:

```text
IDGTK UMLOO ARWOE RTHIS UTETL HUTIA TSLLO
UIMNI TELNJ 7TFYV OIUAU SNOCO 5JI4M EODZZ
```

It ends with `Good luck.` and `3301`. The account describes trial and error leading to a columnar transposition. Removing spaces and arranging the characters into five rows of fourteen gives:

```text
0  1  2  3  4  5  6  7  8  9  10 11 12 13
I  D  G  T  K  U  M  L  O  O  A  R  W  O
E  R  T  H  I  S  U  T  E  T  L  H  U  T
I  A  T  S  L  L  O  U  I  M  N  I  T  E
L  N  J  7  T  F  Y  V  O  I  U  A  U  S
N  O  C  O  5  J  I  4  M  E  O  D  Z  Z
```

Reported zero-based column order: `2 8 9 1 12 13 11 4 5 7 3 0 6 10`. Reading the reordered rows produces:

```text
GOOD WORK
ULTIMATE TRUTH IS THE ULTIMATE ILLUSION
JOIN US AT FV7LYUCMEOZZD5J4ONIO
```

The final `N` is absent. The account assumes it was omitted to fit the rectangular transposition and supplies the formatted address `fv7lyucmeozzd5j4.onion`. That final-letter restoration is an interpretation, not an additional decrypted character.

## 4. Third onion: server status, 1033 square, and welcome pages

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Part_1_%282014%29#The_Third_Onion)

The source presents this section chronologically despite branching investigations. The service was reportedly later taken offline. The first visitor found a blank page, followed by:

```html
<!--1033-->
87de5b7fa2
```

One byte at a time was added at widely varying intervals; some timing data was collected. In parallel, a solver reportedly used DirBuster and discovered an Apache server-status page. The source calls this an apparent misconfiguration but says intentionality is unknown. Its suggestion that Cicada was alerted by the discovery is an inference from the subsequent change, not demonstrated causation.

### 4.1 Image pair and out-of-bounds data

A long string appeared on the status page. It reportedly contained a forward JPEG, intervening “OOB” (out-of-bounds) data, and a reversed JPEG:

```text
[FF D8 ... JPEG ...] [intervening data] [... JPEG ... D8 FF]
```

The account describes the reconstructed images as the same except for OOB data and supplies:

```sh
xxd -p -r < server-status.hex > server-status.jpg
cmp -l server-status.jpg rev.server-status.jpg
```

Displayed OOB string:

```text
a02373230202020202833313020202020213433302020202021333130202020202135313a06363
330202020202939313020202020203331302020202020323330202020202028313a06323230202
020202534323020202020202139302020202025343230202020202632323a08313020202020203
2333020202020203331302020202029393130202020202636333a0135313020202020213331302
02020202134333020202020283331302020202022373230a0a
```

The source says the bytes are printable ASCII, many resembling digits, and gives these intermediate commands:

```sh
xxd -b oob.hex oob.bin
xxd -r oob.bin oob-rev.bin
```

It also gives a more concrete one-liner from the image:

```sh
dd if=server-status.jpg bs=1 skip=$((0x00521e4)) count=357 status=noxfer | rev | xxd -p -r
```

**Editorial caution:** the prose and intermediate commands do not unambiguously specify all representation changes. `cmp -l` reports differences; the two `xxd` commands alone should not be assumed to specify reversal. The printable-byte assertion also needs checking against the original data. Preserve raw inputs and distinguish reversing text from reversing byte sequences.

Reported matrix, identified as a magic square with constant `1033`:

```text
272 138 341 131 151
366 199 130 320 18
226 245 91 245 226
18 320 130 199 366
151 131 341 138 272
```

### 4.2 Visible runes and the same square

The upper runes reportedly required transliteration only:

```text
SOME WISDOM
THE PRIMES ARE SACRED
THE TOTIENT FUNCTION IS SACRED
ALL THINGS SHOULD BE ENCRYPTED
```

The lower red heading reads `KNOW THIS:`. The mixed table beneath it is transcribed as:

```text
272       138     shadows 131      151
aethereal buffers void    carnal   18
226       obscura form    245      mobius
18        analog  void    mournful aethereal
151       131     cabal   138      272
```

Applying the 2013 numerical values reportedly yields the same `1033` matrix as the OOB route. This is a reported agreement between two derivations, not two independently verified originals in this documentation.

### 4.3 Main-page completion and status-page changes

After about a day of speculation about the square, the main string stopped growing. The account attributes a final update of January 11, 01:09:01 GMT to an HTTP header:

```text
87de5b7fa26ab85d2256c453e7f5bc3ac7f25ee743297817febd7741ededf07ca0c7e8b1788ea4131441a8f71c63943d8b56aea6a45159e2f59f9a194af23eaabf9de0f3123c041c882d5b7e03e17ac49be67cef29fbc7786e3bda321a176498835f6198ef22e81c30d44281cd217f7a46f58c84dd7b29b941403ecd75c0c735d20266121f875aa8dec28f32fc153b1393e143fc71616945eea3c10d6820bd631cf775cf3c1f27925b4a2da655f783f7616f3359b23cff6fb5cb69bcb745c55dff439f7eb6a4094bd302b65a84360a62f94c8b010250fcc431c190d6ed8cc8a3bfce37dddb24b93f502ad83c5fa21923189d8be7a6127c4105fcf0e5275286f2
```

The source calls this 512 characters/256 bytes/2048 bits and says it “matched” the previous onion's growing string. **Editorial observation:** the displayed values differ, starting `87de…` versus `6342…`; literal equality is not supported. “Matched” may refer to length or behavior, but that interpretation is not established.

At January 11, 10:07 UTC, the status page reportedly changed to [another hex payload](https://infotomb.com/laqs9.txt), containing two images with the second reversed. The wiki labels them `LiberPrimuspage5.jpg` and `LiberPrimusPage6.jpg`.

### 4.4 Welcome pages and Vigenère behavior

OutGuess on the first image reportedly yielded a [signed hex message](https://infotomb.com/t5uuz.txt), itself encoding a small JPEG with more runes. The wiki's small-image filename refers to page 6; filenames alone should not settle page identity.

First large image, initial transliteration (case preserved from the source):

```text
uWGsSfc rSugpWW fwxtclW ym WS tcnF GmXXmmw FpdGXr oW Xmi ff euG SuF yp rF ipF cF Fnw bxmd rXi fpc SSFc rTp fjmo ScwX bFw bWls ry jF r mcTSFtcpw mgS cGpu Sc rew Xpi bybx flir rm cgb yr cfu TpXjwtfW jgb FTffWpT pfax jmepGsosm wSjl wxuT FwmT dyjc sXxoGrmbw rmi dyjc xhuypl jGymfjpSuX wSj dwxu alasmXSx Fm Xmi py Fmuf
```

The reported cipher was Vigenère using reversed gematria and key `DIUINITY`, interpreted as “divinity.” On each `F`, that symbol was left unencrypted and the running key reset. The exact rune/token interpretation and whether key state continues across pages require reproduction, not assumptions from conventional Latin-letter Vigenère.

Reported plaintext:

```text
WELCOME:
WELCOME, PILGRIM TO THE GREAT JOURNEY
TOWARD THE END OF ALL THINGS.
IT IS NOT AN EASY TRIP, BUT FOR THOSE WHO
FIND THEIR WAY HERE IT IS A NECESSARY ONE.
ALONG THE WAY YOU WILL FIND AN END TO ALL
STRUGGLE AND SUFFERING, YOUR INNOCENCE, YOUR
ILLUSIONS, YOUR CERTAINTY, AND YOUR REALITY.
ULTIMATELY, YOU WILL DISCOVER AN END TO SELF.
```

OutGuess on the second large image reportedly produced unhelpful output, characterized by the authors as garbage. That observation does not prove the absence of hidden information. Initial transliteration:

```text
my yS Fxrjse ewn djusxytetm Sry ds neFdX pbunWGjXF jgb pTx pnwwilmF lpbuoWX rXWf rrSjm rmi dyj hlfu juXlTW SjoSrrm umsc WS liFFcl wi lt peup WXpTtb tme ulole Sjp uW lcg WgsXtm
bmrTfp wrj rxc G jWQ je ym dyjcFXuf pfa ccW r ujr ambp gpbunWGf nxe ygiWGumtcgWW jF bpwd fyx Fuf Sjp xlTWa lT cyuX
ce lFSixTsFhF Tyflcer pfax rbe Fcbf
```

Reported Vigenère plaintext:

```text
IT IS THROUGH THIS PILGRIMAGE THAT WE SHAPE
OURSELVES AND OUR REALITIES.
JOURNEY DEEP WITHIN AND YOU WILL ARRIVE OUTSIDE.
LIKE THE INSTAR, IT IS ONLY THROUGH GOING
WITHIN THAT WE MAY EMERGE:

WISDOM:
YOU ARE A BEING UNTO YOURSELF.
YOU ARE A LAW UNTO YOURSELF.
EACH INTELLIGENCE IS HOLY.
FOR ALL THAT LIVES IS HOLY.
```

The red footer reads `:AN INSTRUCTION: COMMAND YOUR OWN SELF :`.

At January 11, 10:22 UTC, the status page changed again. The source calls this fourteen minutes after the 10:07 update, although the displayed minute timestamps differ by fifteen minutes. The first image remained intact; most data for the second was replaced and rendered as a corrupt, incomplete JPEG. The source links the archived `hw0l5.txt` payload. Exact timestamps and original captures are needed to distinguish rounding, transcription, or a genuine discrepancy.

### 4.5 Small hidden image

The smaller image extracted from the first page was reportedly decoded with Vigenère and key `welcome pilgrim to the`. Offsets:

```text
22, 11, 9, 24, 26, 10, 11, 16, 19, 9, 23, 25, 19, 10, 13, 26, 27, 11
```

Reported output:

```text
A U O W Y F X L 5 L C S F J 3 N O N IA N
```

The account formats this as `avowyfgl5lkzfj3n.onion`. The displayed token sequence is not a literal spelling of that URL. Rune transliteration ambiguities and the source's normalization must be resolved before treating the URL as a mechanically reproduced result.

## 5. Fourth onion: 3301 string, compressed pages, and koan

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Part_1_%282014%29#The_Fourth_Onion)

The account says this service was later taken offline. Its initial document included `</head><body><!--3301-->`, the following hex, an `<hr>`, and footer `Apache Server at 127.0.0.1 Port 5243`, followed by closing body/HTML tags:

```text
bf1d5574ca36efd524e6c34c26cbd628b19aa835aceb94ea7f2ca7f33d1b8f51476bc597d4bf9ad5111d8f39ef5351b3b090bce47f023002fe69928e79f6f8147f6fe051f2f159041f932f5190308d7441fc3cecead0851662d3217485827e640a4183fa5bc8cef5ff7d1473d2746a37fbc8b94318ff0d3aeb467017c0ea5cb33b3e6967453986e1450b35ad47861f679cf7db5a6c170bcfb67544983ec1e36b27ee8c5721da39d27dbfa0cdc15ba3cbaa425e8a8b96b81ab665f3ebc41563a0e9270695d3d68887cfab2c07b290718307f764afba684b17fcfd71323f64206e5fa378b4ee89e80885733080065dd34a5c838898906b8d43de9f1d8eb6922bad
```

The source calls it 512 characters/256 bytes. The onion shortly went offline, returning January 29 at 00:05 GMT with a signed message containing multiline hex and no surrounding HTML. Reference: [vnq3e.txt](https://infotomb.com/vnq3e.txt), with a Wayback archive linked from the source.

The bytes began `1F 8B`. Reported commands:

```sh
xxd -p -r onion4.hex onion4.gz
file onion4.gz
gzip -d onion4.gz
```

The displayed `file` result identifies gzip data, original name `data.out`, Unix origin, and modification time `Fri Jan 24 15:10:12 2014`. This is reported embedded metadata, not a verified creation time. Decompression reportedly produced four images, labeled `Onion-0.jpg` through `Onion-3.jpg`.

A substitution described as similar to onion 2, with a linked `SubstitutionKeyKoan.jpg`, produced:

```text
A KOAN
A MAN DECIDED TO GO AND STUDY WITH A MASTER.
HE WENT TO THE DOOR OF THE MASTER
"WHO ARE YOU WHO WISHES TO STUDY HERE?"
ASKED THE MASTER.
THE STUDENT TOLD THE MASTER HIS NAME.
"THAT IS NOT WHO YOU ARE THAT IS ONLY WHAT YOU ARE CALLED.
WHO ARE YOU WHO WISHES TO STUDY HERE?" HE ASKED
AGAIN.
THE MAN THOUGHT FOR A MOMENT, AND REPLIED
"I AM A PROFESSOR."
"THAT IS WHAT YOU DO, NOT WHO YOU ARE"
REPLIED THE MASTER. "WHO ARE
YOU WHO WISHES TO STUDY HERE?"
CONFUSED, THE MAN THOUGHT SOME MORE.
FINALLY, HE ANSWERED, "I AM A HUMAN BEING."
"THAT IS ONLY YOUR SPECIES, NOT WHO YOU ARE.
WHO ARE YOU WHO WISHES TO STUDY HERE?"
ASKED THE MASTER AGAIN.
AFTER A MOMENT OF THOUGHT, THE PROFESSOR REPLIED
"I AM A CONSCIOUSNESS INHABITING AN ARBITRARY BODY."
"THAT IS MERELY WHAT YOU ARE NOT WHO YOU ARE"
WHO ARE YOU WHO WISHES TO STUDY HERE?"
THE MAN WAS GETTING IRRITATED. "I AM," HE STARTED,
BUT HE COULD NOT THINK OF ANYTHING ELSE TO SAY,
SO HE TRAILED OFF. AFTER A LONG PAUSE THE MASTER REPLIED
"THEN YOU ARE WELCOME TO COME STUDY."
AN INSTRUCTION

DO FOUR UNREASONABLE THINGS EACH DAY.
```

The article does not fully specify the substitution in prose; the key image remains necessary evidence.

OutGuess on the image labeled `Onion-2.jpg`, referred to in the command as `onion4image3.jpg`, reportedly recovered:

```sh
outguess -r onion4image3.jpg out
```

```text
For those who have fallen behind:

TL BE IE OV UT HT RE ID TS EO ST PO SO YR
SL BT II IY T4 DG UQ IM NU 44 2I 15 33 9M

Good luck.

3301
```

The reported columnar transposition has period `7` and key `1736254`. Result:

```text
TOBELIEVETRUTHISTODESTROYPOSSIBILITYQ4UTGDI2N4M4UIM59133
```

The account separates this into “TO BELIEVE TRUTH IS TO DESTROY POSSIBILITY” and `Q4UTGDI2N4M4UIM59133`, then extracts `q4utgdi2n4m4uim5.onion`. The remaining `9133` is explicitly unexplained. Retain that suffix; it is not established padding.

## 6. Fifth onion: Interconnectedness, portrait, and book code

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Part_1_%282014%29#The_Fifth_Onion)

### 6.1 Audio and metadata

The service initially contained a PGP-signed message and shortly went offline. Converting its hex to binary and identifying the file reportedly revealed an MP3:

```sh
xxd -p -r onion5.hex onion5.bin
file onion5.bin
mv onion5.bin onion5.mp3
id3v2 -l onion5.mp3
```

The shown tool output instead names `his5u.mp3`. It reports ID3v2 title `Interconnectedness`, artist `3301`, and no ID3v1 tag. These are tag values, not independent authorship evidence.

The account gives a Gematria Primus 2013 sum of `772` for the title, notes that the reversed number is prime, and gives a duration of `277.133` seconds. These numerical associations are retained without assuming deliberate design. The audio later reappears as a carrier of hidden magic squares.

### 6.2 Portrait and number columns

On January 31 the onion reportedly returned with an image identified as Goya y Lucientes' *Portrait of Andrés del Peral*. Filtering/comparison allegedly revealed a superimposed portrait of Grigori Rasputin at upper right and a cicada logo at upper left. The source calls the portrait's and Rasputin's significance undetermined. Those identifications and visual observations have not been independently checked here.

The displayed left number column is:

```text
181
7
15
16
966
456
351
7
```

The source says it sums to `1033`. **Editorial check:** the eight printed values sum to `1999`. Removing `966` happens to leave `1033`, but that is not grounds to alter the transcription or assert which value is wrong.

The right column is:

```text
966
1071
626
204
434
```

Its reported sum `3301` does agree with arithmetic on the displayed values.

OutGuess on the portrait reportedly produced bzip-compressed data:

```sh
outguess -r onion5portrait.jpg onion5portrait.outguess
file onion5portrait.outguess
bzip2 -d onion5portrait.outguess
```

Decompression yielded a [signed text message](https://github.com/micheloosterhof/cicada-2014/blob/master/stage08/index).

### 6.3 Three hex blocks and Gödel, Escher, Bach

Three hex blocks in that message reportedly decode to two JPEGs and an MP3. The source identifies them as an equation associated with Gödel's incompleteness theorem, Escher's *Eye* (1946), and a three-second extract from Bach's Trio Sonata in G Major, BWV 1039. It explicitly records an alternative musical identification, BWV 1033. Both should remain visible until checked against the actual recording.

Together these were interpreted as pointing to Douglas Hofstadter's *Gödel, Escher, Bach: An Eternal Golden Braid*. The final message portion is a book code in the format **chapter : line : word : letter**. The following preserves each token, reported section/page, and character:

| Token | Reported section | Page | Character |
| --- | --- | --- | --- |
| 3PI:6:1:3 | Three-Part Invention | 29 | u |
| LML:1:1:1 | Little Harmonic Labyrinth | 103 | t |
| 3 | Literal digit | — | 3 |
| ETOATS:19:9:1 | Edifying Thoughts of a Tobacco Smoker | 480 | q |
| ...AF:5:3:1 | ... Ant Fugue | 311 | t |
| AMO:13:10:1 | A Mu Offering | 231 | z |
| CC:8:6:1 | Crab Canon | 199 | b |
| CBIA:3:7:2 | Canon by Intervallic Augmentation | 153 | r |
| CFAF:5:23:6 | Chromatic Fantasy, And Feud | 177 | v |
| SPR:1:8:1 | Six-Part Ricercar | 720 | s |
| 7 | Literal digit | — | 7 |
| C[1]:4:5:3 | Contracrostipunctus | 75 | d |
| AWDV:6:2:1 | Aria with Diverse Variations | 391 | t |
| C[2]:2:17:5 | Contrafactus | 633 | v |
| SC:3:17:1 | Sloth Canon | 681 | z |
| AOGS:2:8:1 | Air on G's String | 431 | p |
| ONION | Literal suffix | — | ONION |

The reported result is `ut3qtzbrvs7dtvzpONION`, formatted as `ut3qtzbrvs7dtvzp.onion`. The precise edition and line-numbering conventions remain reproduction dependencies; the page numbers alone do not establish them.

## 7. Sixth onion: four pages, submission request, and three squares

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Part_1_%282014%29#The_Sixth_Onion)

At `ut3qtzbrvs7dtvzp.onion`, a large hex block reportedly followed an HTML comment. The sentence introducing the comment is incomplete in the extracted account; no missing comment value is supplied here. The source links [hrz8z.txt](https://infotomb.com/hrz8z.txt).

This payload reportedly contained four sequential JPEGs, none reversed, labeled `Pg1.jpg` through `Pg4.jpg`. Their runes were described as unenciphered beyond transliteration. The page divisions and split words below follow the wiki transcription rather than reconstructed flowing prose.

### 7.1 Visible page text

Page 1:

```text
THE LOSS OF DIVINITY: THE CIRCU
MFERENCE PRACTICES THRE
E BEHAVIORS WHICH CAUSE TH
E LOSS OF DIVINITY.

CONSUMPTION: WE CONSUME TOO
MUCH BECAUSE WE BELIEVE THE
FOLLOWING TWO ERRORS WITHIN THE DEC
EPTION.
    1 WE DO NOT HAVE ENOUGH
    OR THERE IS NOT ENOUGH
```

Page 2:

```text
    2 WE HAVE WHAT WE HAVE N
    OW BY LUCK, AND WE WILL NOT
    BE STRONG ENOUGH LATER T
    O OBTAIN WHAT WE NEED.

MOST THINGS ARE NOT WORTH CONSUM
ING:

PRESERVATION: WE PRESERVE
THINGS BECAUSE WE BELIEVE WE AR
E WEAK. IF WE LOSE THEM WE WILL NO
T BE STRONG ENOUGH TO GAIN THEM
AGAIN. THIS IS THE DECEPTION.
```

Page 3:

```text
MOST THINGS ARE NOT WORTH PRESERV
ING:
ADHERENCE: WE FOLLOW DOGMA
SO THAT WE CAN BELONG AND BE RIGH
T. OR WE FOLLOW REASON SO WE CAN
BELONG AND BE RIGHT.

THERE IS NOTHING TO BE RIGHT ABOUT.
TO BELONG IS DEATH.

IT IS THE BEHAVIORS OF CONSUMPT
ION, PRESERVATION, AND ADHEREN
```

Page 4:

```text
CE THAT HAVE US LOSE OUR PRIMAL
ITY AND THUS OUR DIVINITY:

SOME WISDOM: AMASS GREAT W
EALTH. NEVER BECOME ATTA
CHED TO WHAT YOU OWN. BE
PREPARED TO DESTROY ALL THAT
YOU OWN:
AN INSTRUCTION: PROGRAM YOU
R MIND. PROGRAM REALITY
```

These are claims and instructions in the reported puzzle text, not beliefs endorsed by this project.

### 7.2 Hidden messages and number-square borders

All four images reportedly held PGP-signed OutGuess messages. The first message body is:

```text
Create one Tor hidden service that can accept CGI file uploads.

When this hidden service returns and can accept input, post the
three magic squares and the URL to your Tor hidden service here.

Work alone.
3333333333333333
310    12    103
3              3
312    14    123
3              3
310    12    103
3333333333333333

Good luck.

3301
```

The inner number square is:

```text
 10    12    10

 12    14    12

 10    12    10
```

The account correctly distinguishes this inner arrangement from a magic square. The border character reportedly varies by page: `3`, `3`, `0`, `1`, spelling `3301`. The source describes that border as the messages' only difference; this document has not compared their signed originals.

The onion then went offline and reportedly returned six days later with another signed message. Its operative body is:

```text
Hello.  You have done well to come this far.

Please paste the magic squares into the appropriate textareas below, then
provide the URL to your Tor hidden service.

The path to your CGI script which accepts uploads should be '/cgi-bin/upload'
and the HTML form input which accepts file uploads should be named 'file'.

Additionally, please generate a GnuPG key pair, and place the public key
in the location '/key.asc'.
We will contact you soon.

Good luck.

3301
```

The associated page reportedly had three textareas for the squares and one field for the submitter's hidden-service URL. The account says any square satisfying the relevant criteria was accepted, giving as an example an order-five square with constant 3301 for the first box. That is an account of server behavior, not an independently tested specification of every acceptance condition.

### 7.3 OpenPuff and magicsquares.txt

Only after the submission page appeared, according to the narrative, was hidden data found in the earlier *Interconnectedness* MP3. The source attributes the steganography to OpenPuff and identifies a recovered file named `magicsquares.txt`. It does not provide a complete extraction recipe, password derivation, or tool configuration here.

The file's three reported matrices are retained in its order.

Order five, reported constant 3301:

```text
434     1311    312     278     966

204     812     934     280     1071

626     620     809     620     626
1071    280     934     812     204

966     278     312     1311    434
```

Order seven, reported constant 1033:

```text
7       375     236     190     27      17      181

351     223     14      47      293     98      7

456     232     121     114     72      23      15

16      65      270     331     270     65      16

15      23      72      114     121     232     456

7       98      293     47      14      223     351

181     17      27      190     236     375     7
```

Order five, reported constant 1033:

```text
272     138     341     131     151

366     199     130     320     18

226     245     91      245     226

18      320     130     199     366

151     131     341     138     272
```

The final matrix matches the earlier 1033 square as transcribed. **Editorial checks:** for each displayed matrix, every row, every column, and both main diagonals sum to the reported constant. These contain repeated values; the check concerns equal sums, not the additional properties of a normal magic square. Arithmetic agreement does not verify extraction from the MP3.

### 7.4 Submission response: 107, 167, and 229

The displayed response says `Thank you for you submission.` and references three images, `107.jpg`, `167.jpg`, and `229.jpg`. The source notes improperly closed HTML. Its displayed HTML also includes view-source formatting artifacts, so it should not be treated as a pristine HTTP response.

The first two pages reportedly use Vigenère with key `FIRFUMFERENFE`, attributed to `CIRCUMFERENCE`. The source itself adds `[How?]`, leaving the derivation unexplained. Preserve that uncertainty rather than presenting the key as an obvious consequence of the word.

Reported plaintext, including the spelling `LESSION` and the page break:

```text
A KOAN: DURING A LESSION: THE MAS
TER EXPLAINED THE I:"THE
I IS THE VOICE OF THE CIRCU
MFERENCE,"HE SAID.WHEN AS
KED BY A STUDENT TO EXPLAIN
 WHAT THAT MEANT, THE MASTER SA
ID"IT IS A VOICE INSIDE YOUR H
EAD"."I DON'T HAVE A VOICE I
N MY HEAD," THOUGHT THE STUDENT,
AND HE RAISED HIS HAND TO TE
LL THE MASTER.THE MASTER STOP

--page change--
PED THE STUDENT,AND SAID"THE
VOICE THAT JUST SAID YOU HAV
E NO VOICE IN YOUR HEAD, IS THE
I."AND THE STUDENTS WERE ENL
LIGHTENED:
```

The last page reportedly requires only rune-to-English transcription:

```text
AN INSTRUCTION:QUESTION ALL
THINGS: DISCOVER TRUTH INSIDE
YOURSELF: FOLLOW YOUR TRU
TH: IMPOSE NOTHING ON OTHERS.
KNOW THIS:
434 1311 312 278 966
204 812 934 280 1071
626 620 809 620 626
1071 280 934 812 204
966 278 312 1311 434
```

Its numerical block is the same 3301 square listed above.

## 8. End of this account and later page release

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Part_1_%282014%29#The_End)

The authors describe a period of collective silence after submission: IRC participation dwindled and the onions went offline. An author's note distinguishes what the group heard from what individuals might have received and asserts that Cicada recruits individuals rather than groups. That recruitment model is the author's interpretation, not independently established organizational knowledge.

The account says that much later, some people claimed to have received messages similar to the end of 2013, while others received an onion link containing 58 additional Liber Primus page images. Its wording explicitly qualifies the former as claims. It supplies neither a comprehensive recipient record nor a precise date for this event.

The source points to its [Post-2014 continuation](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29) for those pages. This document ends at that handoff; it does not treat Part 1 as an account of the later pages' solutions or current status.

The article also links a [schematic of the 2014 steps](http://imgur.com/42VKTWB). That schematic is a referenced aid, not independently inspected evidence here.

## 9. Discrepancies and unresolved details to carry forward

This register identifies documentation/reproduction questions, not proposed solutions or a ranked project roadmap. Lack of an explanation in this account does not imply nobody has investigated a detail elsewhere.

| Detail | Account's claim or omission | Treatment for future work |
| --- | --- | --- |
| Emerson standalone `3` | Explained as a letter, retained as a digit in the URL | Reproduce against the exact text before codifying indexing |
| Authenticity | Messages described as signed/authentic | Obtain original signed bytes and establish key provenance |
| RSA implementation | Perl inferred from module name | Treat as an implementation lead, not proof of origin |
| Timing observations | Incomplete logs; approximate intervals | Preserve timestamps, time zones, and collection gaps |
| Second onion initial/final string | Same full string printed twice | Seek time-stamped captures |
| `761` | Called a palindromic prime | Not palindromic; gematria sum remains to reproduce |
| Large payload length | `3641299 (?)` | Preserve uncertainty; compare with archived byte count |
| Inversion and reversal | Ambiguous short XOR mask and OOB commands | Specify representation and exact operation at each step |
| Warning plaintext | `THEIR NUMBERS` versus `THE NUMBERS` | Keep both variants until checked against image and sums |
| Warning emirps | Some asterisks contradict decimal reversal | Separate original flags from computed classification |
| Third onion string | Said to match previous string | Displayed bytes differ; intended meaning unknown |
| Status-page discovery | Misconfiguration versus intentional clue | Both remain possible in this account |
| Status-page replacement | Corrupt image after 10:22 update | Retain both versions; do not discard as irrelevant |
| Update interval | Fourteen minutes versus displayed 10:07/10:22 | Recover exact timing evidence |
| Welcome Vigenère | Reversed table, exceptional `F`, resetting key | Confirm tokenization, reset timing, and page continuity |
| Small image destination | Token sequence differs from formatted URL | Record normalization instead of silently substituting letters |
| Fourth-onion substitution | Explained partly by key image | Recover and transcribe that image |
| `9133` | Unexplained suffix | Preserve as data |
| Portrait/Rasputin | Identifications with unknown significance | Inspect original media; unknown is not “noise” |
| Portrait left column | Printed values sum to 1999, claimed 1033 | Preserve transcription and discrepancy |
| Music extract | BWV 1039 versus BWV 1033 | Retain competing identifications |
| OpenPuff | Tool named without complete extraction procedure | Recover original carrier, settings, and any passwords |
| Submission validation | Broad acceptance claim with one example | Historical report, not a complete validation specification |
| `FIRFUMFERENFE` | Derivation from CIRCUMFERENCE marked `[How?]` | Preserve the unexplained derivation |
| Final response/recruitment | Private receipt claims and collective silence | Do not infer individual outcomes from group reports |

### 9.1 Referenced artifacts that remain external

The relevant source-section links above lead to the image galleries and original/mirror links. Original images have not been visually inspected in preparing this document. Consequently, typography, rune shapes, illustrations, red ink, borders, spacing, image dimensions, and steganographic content are not exhaustively represented by this text.

| Source stage | Referenced visual or binary evidence |
| --- | --- |
| Beginning | Twitter image `zN4h51m.jpg`; PGP signature/key links; [linked Emerson text](https://www.math.dartmouth.edu/~doyle/docs/self/self.pdf) |
| First onion | Four-painting Blake collage, labeled `1033`; linked Perl decryption program |
| Second onion | Timing logs and illustrations; large replacement payload; Liber Primus, Intus, Runes images; 2013 table and solver-created 2014 table |
| Third onion | Forward/reversed server-status images; magic-square illustration; welcome-page pair; nested small JPEG; reversed-gematria illustration; corrupt replacement; small-image cleartext illustration |
| Fourth onion | Signed gzip hex; four koan pages; substitution-key image |
| Fifth onion | Signed audio payload; Interconnectedness MP3 and metadata; portrait and comparison image; compressed OutGuess output; Gödel/Escher images and disputed Bach clip |
| Sixth onion | Four initial pages; signed OutGuess messages and borders; submission-page screenshot; original MP3/OpenPuff extraction; 107.jpg, 167.jpg, 229.jpg |
| End | Later 58-page release; [Post-2014 continuation](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29); 2014 schematic |

The linked Emerson PDF is headed *Self-Reliance*, while the article names *Self-Reliance and Other Essays*. That distinction is recorded as a source/edition dependency; the book cipher has not been recomputed from the PDF.

### 9.2 Verification performed for this document

- Read all narrative sections of the source through its ending and infographic reference.
- Preserved all six reported onion destinations, the three 512-character strings, RSA parameters and ciphertext, both book-code sequences, transposition data, reported Vigenère keys/offsets, page plaintexts, and all three magic-square matrices.
- Checked the RSA factor product, modulus length, three hex-string lengths, portrait-column arithmetic, and magic-square row/column/diagonal sums.
- Kept original source claims distinguishable from arithmetic checks and editorial observations.
- Did not reperform OutGuess/OpenPuff extraction, signature verification, RSA decryption, book-cipher indexing, rune-image transcription, media identification, or live service interactions.

This is an annotated research reference. Establishing reproducible derivations will require original artifacts and explicit transformation rules, especially where this account is incomplete or internally inconsistent.
