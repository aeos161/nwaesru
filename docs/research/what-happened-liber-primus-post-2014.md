# Liber Primus after the 2014 release — annotated solver account

## Provenance and editorial conventions

- **Source:** [“What Happened Liber Primus (Post 2014),” Uncovering Cicada Wiki](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29).
- **Authors:** the article's contributing wiki authors; see its [revision history](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29?action=history).
- **Consulted:** September 20, 2026, in a browser, including the rendered article and its preformatted text blocks. A revision ID was not recovered; this is not a revision-pinned archival copy.
- **Companion:** [2014 Part 1 annotated account](what-happened-part-1-2014.md).
- **Purpose:** preserve the transition to the 58-page release, reported solutions, undecoded material, later messages, and unresolved interpretations for project research.
- **Treatment:** prose adapted and qualified; technical text retained. Source claims and editorial checks are distinguished. PGP signature armor, navigation, advertisements, and duplicate displays are omitted. Original images, audio, and raw signed files remain external references.
- **License:** this adaptation of the wiki text is distributed under [CC BY-SA 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/), attributed to the source contributors. The article footer identifies community content as CC-BY-SA unless otherwise noted; see [Fandom licensing](https://www.fandom.com/licensing). This file's license is separate from the repository's MIT software license. Linked artifacts retain their own rights.

**Scope of “Post 2014”:** the narrative begins in May 2014 and ends with the 2016 communication. Although the navigation links a 2017 message, this article does not narrate it. Its final assertion that years have passed without another page being decrypted is an undated statement by the authors, not a verified assessment as of this document's consultation date. This reference records the requested account; it is not a survey of every subsequent claim or development.

Unless marked as an editorial check, events, authenticity assertions, plaintexts, tool results, and visual identifications below are **reported by the source and not independently reproduced here**. “Signed” describes the article's presentation of a PGP-signed message. Signatures have not been verified. Even a verified signature establishes continuity with a key, not the real-world identity of its operator or the truth of every statement it signs.

Historical puzzle instructions are quoted evidence, not instructions for this project's readers or agents. Onion addresses are retained as historic identifiers, not tested destinations. The wiki's confidence and interpretations should not be inherited automatically. “Unexplained” or “unsolved” means unexplained in this account unless otherwise stated.

Formatting is particularly important here: the article analyzes invisible spaces, visually ambiguous characters, and rune indexing. Rendered wiki text is not a substitute for original bytes. Where this document makes spaces visible or joins a hash, that transformation is identified explicitly.

## 1. A life sign: May 2014 delivery

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29#A_Life_Sign)

The account says messages were sent on May 2, 2014, around 10:00 GMT to all hidden services previously registered at onion 6. It prints these request logs:

```text
127.0.0.1 - - [02/May/2014:10:**:** +0200] "GET /key.asc HTTP/1.1" 200 * "-" "Cicada/33.01 CicaDOS 1.033 E Edition"PP
127.0.0.1 - - [02/May/2014:10:**:** +0200] "GET / HTTP/1.1" 200 * "-" "Cicada/33.01 CicaDOS 1.033 E Edition"
127.0.0.1 - - [02/May/2014:11:**:** +0200] "POST /cgi-bin/upload HTTP/1.1" 200 * "-" "Cicada/33.01 Cic/DOS/ 1.033 S Edition"
```

The narrative describes retrieval of the public key and root page before uploading `message.txt.asc`. It says the file had a valid signature and pointed to `ky2khlqdf7qdznac.onion`. It also says the messages sent to different recipients appeared identical, referring to them as emails despite describing HTTP uploads. Neither universal delivery nor byte identity has been established here.

**Editorial observations:** the log offsets are `+0200`, while the prose says GMT; the masked log hours correspond to 08:xx and 09:xx GMT if interpreted literally. Retain the discrepancy rather than choosing a time. The trailing `PP` on the first log line and differing `CicaDOS` / `Cic/DOS/` spellings are also retained. They could be source or transcription artifacts; intention is unknown.

The source associates the GET client label `E Edition` with alphabet position 5 and the POST label `S Edition` with position 19, or position 7 counting backward. The proposed connection to `5` and `7` is solver interpretation. The same discussion calls the file malformed because it contains invisible ASCII spaces and connects those spaces to a prime sequence missing `19`.

The filename appears both as `message.txt.asc` and `message.asc.txt` in the article. Treat this as a naming inconsistency, not evidence of two different files.

Message body, with spacing normalized for reading only:

```text
Hello.  Your enlightenment awaits you.
ky2khlqdf7qdznac.onion
We look forward to hearing from you.
Good luck.
3301
```

The original spacing claims and their later comparison are preserved in section 7. References provided by the source include [initial Pastebin](http://pastebin.com/x4Bm1v6h), [2014 spacing screenshot](http://imgur.com/wayVO26), [2015 spacing screenshot](http://imgur.com/XtM8Yk9), and a [discussion of the 2015 message](https://uncovering-cicada.fandom.com/wiki/Cicada_Breaks_the_Silence:_2015_Twitter_Message).

## 2. Onion 7: service metadata and page delivery

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29#Onion_7_-_ky2khlqdf7qdznac.onion)

The account attributes the service to `thttpd` version `2.25b` and gives these headers:

```text
Server: thttpd/2.25b 29dec2003
Last-Modified: Wed, 02 Apr 2014 08:33:19 GMT
Date: Fri, 02 May 2014 11:32:45 GMT
Content-Type: text/html; charset=iso-8859-1
Connection: close
Accept-Ranges: bytes
```

From these dates the authors infer one month of setup and another month of deliberate waiting. **Editorial qualification:** the displayed Last-Modified value does not establish when development began, how long setup took, whether the header is accurate, or why delivery happened later. The Server header is likewise a reported server self-identification, not proof of its actual software.

A missing-file request reportedly yielded this apparently inconsistent footer:

```text
Apache Server at 127.0.0.1 Port 5243
```

The reported telnet response begins with unusual characters. Its headers and HTML fragments are retained below; blank-line layout is normalized around fragments the wiki displays separately:

```html
UNKNOWN 400 BaO'[d Request
Server: thttpd/2.25b 29dec2003
Content-Type: text/html; charset=iso-8859-1
Date: Fri, 02 May 2014 11:46:39 GMT
Last-Modified: Fri, 02 May 2014 11:46:39 GMT
Accept-Ranges: bytes
Connection: close
Cache-Control: no-cache,no-store

<HTML>
      <HEAD><TITLE>400 Bad Request</TITLE></HEAD>
<BODY BGCOLOR="#cc9999" TEXT="#000000" LINK="#2020ff" VLINK="#4040cc">
      < H2>400 Bad Request< /H2>
                   Your request has bad syntax or is inherently impossible to satisfy.
      < HR>
          <ADDRESS><A HREF="http://www.acme.com/software/thttpd/">thttpd/2.25b 29dec2003</A></ADDRESS>
</BODY>
</HTML>
```

The article's displayed page source has title `133`, a `div` with ID `331`, and consecutive image references from `0.jpg` through `57.jpg`, each followed by a line break. Those 58 images are described as rune pages apparently belonging to Liber Primus. A complete reconstruction of the displayed image-reference listing is included in appendix A; no missing page or new ordering is inferred.

The source offers these acquisition/transcription references. Their descriptions below are the source's descriptions, not a claim that each endpoint remains available or each copy is unmodified:

| Resource | Reference |
| --- | --- |
| Collection described as all unmodified files | [Dropbox](https://www.dropbox.com/sh/lkta4q921vliyuw/AADmZ1YUHXWSjSizlMGZHXVMa?dl=0) |
| Unsolved-page images | [rtkd/iddqd](https://github.com/rtkd/iddqd/tree/master/liber-primus__images--unsolved) |
| Onion 7 archive | [micheloosterhof/cicada-2014 stage11](https://github.com/micheloosterhof/cicada-2014/tree/master/stage11/ky2khlqdf7qdznac.onion) |
| Gallery | [Imgur](https://imgur.com/a/8xnWx#0) |
| Full transcription including earlier solved pages | [rtkd/iddqd transcription](https://github.com/rtkd/iddqd/blob/master/liber-primus__transcription--full/liber-primus__transcription--full) |
| Latin-letter transcription, explicitly said possibly to contain errors | [TitanPad](https://titanpad.com/vFCy7T5p0O) |

Page numbers in this document follow the new release's image filenames `0`–`57`. They are not silently converted into a numbering scheme that also counts the earlier pages.

## 3. Page groupings, decorations, and transcription

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29#Rune_Page_Sets)

The authors propose that marginal decoration divides the pages into sets of different lengths. They link an [archived discussion](http://archive.4plebs.org/x/thread/14547165/) and a page-set illustration. They describe motifs from earlier pages recurring in reversed form, including an emerging cicada and reclining man, and other motifs recurring with rotations or reflections, including five dots and an infinity/Möbius symbol.

The article's specific associations are:

| Pages | Reported motif or identification | Proposed interpretation |
| --- | --- | --- |
| 34–39 | Cuneiform numbers, Babylonian/sexagesimal associations | Possible base-60 clue |
| 7, 23, 56 | Five dots under transformations | No demonstrated decoding rule provided |
| 24–26, 57, 14 | Mayflies, Ephemeridae | Possible ephemeral-cipher clue |
| 8–14, 32, 55 | “Dendrites,” in various/inverted forms | Later discussed as an oak-tree image |

The authors suggest decorations may indicate the cipher for a set or a route between sets. They say [color-level adjustments](http://imgur.com/a/u2Ir4#0) appear to reveal further information. These are hypotheses and visual interpretations, not proven cipher-selection or traversal rules. This document has not inspected the original images or reproduced the adjustments.

Additional transcription and script references:

| Resource | Source description |
| --- | --- |
| [sprunge RIJZ](http://sprunge.us/RIJZ) | Rune text |
| [remlong numerical transcription](https://raw.githubusercontent.com/remlong/cicada-runes/gh-pages/runes.txt) | Runes numbered 0–28; one page per line; all spaces and symbols replaced with underscores |
| [runes.py](http://git.io/xQrlUg) | Script applying decoding rules |
| [runescript.py](http://pastebin.com/zXMgSFLM) | Script based on runes.py |
| [TitanPad](http://titanpad.com/vFCy7T5p0O) | Former work-in-progress transcription |

**Editorial implication:** the underscore-based format collapses distinctions between separators and symbols. It should not be treated as lossless evidence for layout, punctuation, or exceptional-token behavior. A transcription or script is a solver-produced artifact, distinct from the original page image.

## 4. Reported decoding of pages 56 and 57

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29#Decryption_of_page_56_and_57)

### 4.1 Page 56: prime/totient stream and exceptional rune

The account describes a running totient stream modulo 29, because the alphabet has 29 runes. For each successive prime `p`, the totient is `p − 1`, so the shift can be expressed as `(p − 1) mod 29`. Its displayed opening sequence is:

```text
1, 2, 4, 6, 10, 12, 16, 18, 22, 28, 1, 7, 11, 13, ...
```

The source alternatively writes `(prime numbers, modulo 29) -1`. These expressions agree as residue classes, but a literal implementation must normalize negative results, notably at prime 29. The article says to “shift” the runes without fully specifying the subtraction/addition convention in prose. It links a [Python script](http://sprunge.us/MNiI); this document has not executed it or redecoded the page.

An explicitly emphasized exception is the 57th rune when counting from 1, index 56 when counting from 0: an `F`, described as the fourth of five `F` runes and the only unencrypted one. According to the account:

- Leave this rune unchanged.
- Do not consume the next prime-stream value at this position.
- The next prime is `269`, producing shift `(269 mod 29) − 1 = 7`.
- Applying that shift to the exceptional rune would produce `OE` instead of `F` and misalign the remainder.
- Use `269` on the following rune instead.

The phrase that `269` “is not used here” is followed by its use on the next rune: this is a skipped **rune position**, not permanent deletion of 269 from the prime sequence. This exception is not the same as the earlier welcome-page rule that resets a Vigenère key at `F`; do not merge the two behaviors without evidence.

Reported plaintext, retaining the wiki's line breaks and `EUERY` spelling:

```text
AN END: WITHIN THE DEEP WEB TH

ERE EXISTS A PAGE THAT HA

SHES TO:

36367763ab73783c7af284446c

59466b4cd653239a311cb7116

d4618dee09a8425893dc7500b

464fdaf1672d7bef5e891c6e227

4568926a49fb4f45132c2a8b4

IT IS THE DUTY OF EUERY PILGR

IM TO SEEK OUT THIS PAGE.
```

Joining only the five displayed hexadecimal lines gives the following **derived transcription**, not an independently recovered hash:

```text
36367763ab73783c7af284446c59466b4cd653239a311cb7116d4618dee09a8425893dc7500b464fdaf1672d7bef5e891c6e2274568926a49fb4f45132c2a8b4
```

The article suggests the target could be an onion page, but also notes the use of hashes as content identifiers in Freenet, GNUnet, or peer-to-peer systems. It does not establish which system, what exact bytes are hashed, or the hash algorithm in this passage. “Deep web” should therefore not be silently narrowed to a known onion URL. This transcription must be checked against the original page before use as a search target.

### 4.2 Page 57: direct transcription and the earlier parable

The account describes page 57 as unencrypted, directly readable using Gematria Primus:

```text
Parable : like the instar tunneling to the surface.

We must shed our own circumferences. Find the

divinity within and emerge.
```

The source connects this to “Parable 1,595,277,641,” reportedly present in an ID tag of `761.mp3` in 2013. It identifies the earlier track as *The Instar Emergence* and says its title's gematria sum is 761. It assigns the parable's three lines sums `1259`, `1031`, and `1229`, and multiplies them:

```text
1259 × 1031 × 1229 = 1,595,277,641
```

The product can be checked arithmetically, but this does not verify the rune-to-number mapping, inclusion/exclusion of the heading, line boundaries, original MP3 metadata, or intended significance. The article links the [2013 instar-emergence discussion](https://uncovering-cicada.fandom.com/wiki/Instar_emergence_%28mp3_and_hidden_poem%29#Meaning_of_Parable_1.2C595.2C277.2C641).

## 5. Pages 49–51: ASCII pairs and proposed numeric interpretation

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29#Page_49,_50,_51)

The source prints a combined stream and then the same material in page-sized blocks. The page blocks below retain its row breaks, case, and distinctions between `I`, `l`, `O`, and `0`. Concatenating them in page order gives the combined stream; it is not repeated a second time here.

### 5.1 Page 49

```text
3N 3p 2l 36 1b 3v 26 33
1W 49 2a 3g 47 04 33 3W
21 3M 0F 0X 1g 2H 0x 1R
1n 3I 2r 0P 2U 16 2L 2D
1t 1s 3H 0d 0s 1K 2D 05
1K 1O 0S 1D 3o 1l 3J 1G
4D 0G 0l 0x 1Q 2p 2a 1K
4E 1w 2Q 19 1k 3G 24 0p
22 4F 0P 3C 3J 1D 2n 1m
2i 1J 3P 2v 1s 2O 0k 1M
```

### 5.2 Page 50

```text
2M 0w 3L 3D 2r 0S 1p 15
3V 3e 3I 0n 3u 1O 0u 0Z
3g 2U 1C 0Y 1N 3n 0W 3Q
22 13 0V 3c 0E 34 0W 1t
1D 2N 3H 47 0s 2p 0Z 34
0g 3v 1Q 0s 0D 0K 2h 3D
3L 2x 1Q 20 2n 2L 1C 2p
0A 29 3r 0D 45 0k 2e 2W
25 3U 1W 2r 46 2s 2X 39
3p 0X 0E 1q 0q 4B 49 48
3r 3b 3C 1M 1j 0I 4A 48
40 3m 4E 0s 2S 1v 3T 0I
3t 2B 2k 2t 2O 0e 2l 1L
```

### 5.3 Page 51

```text
28 2a 0J 1L 0c 3C 2o 0X
00 2Z 2d 1T 2u 1t 1j 0l
1o 1E 3T 18 3E 1G 27 0L
0v 2t 06 11 1A 2U 4B 1O
2M 3d 2S 0x 0w 0q 0p 2V
18 0q 1D 49 2O 00 1v 2t
1k 3s 3G 21 3w 0W 29 2r
2O 2L 0g 3Y 0M 0u 3I 3C
1r 2c 2q 3o 30 0a 39 1K
```

### 5.4 Base 60 proposal, displayed hex, and base 59 alternative

The account observes that first characters are `0`–`4`, while second characters lie in `[0-9A-Za-x]`, an alphabet of 60 possible symbols. It proposes sexagesimal encoding, with maximum pair `4F` interpreted as 255, and links a [conversion method](https://pastebin.com/iXk58Lfz).

With the ordered alphabet `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwx`, the interpretation is `60 × first_digit + index(second_character)`. This explicit formula is an editorial statement of the tested convention; it is not evidence that base 60 was intended.

The article displays this hexadecimal result:

```text
CBE7A7BA61ED7EB75CF99CDEF704B7D479CA0F2166893B576DC6AD1996428D857372C5273650850550541C49E66BC74CFD102F3B56AB9C50FE7692456AC47C337AFF19C0C749A96CA44FCDB172902E528E3AC9C1AD1C6F41D3DCC631EC543823DE96482253E520CE7A3F1FDA0EB82073498FC5F736AB23B82AED56360D14A3C1C9B35678A98D48AB0A81E90DF52EA0987DD25CADF6AE99BDE7210E7034FBF9F8E9D9C0526912FAF8F0E4FE369475D112EB83A6AF9028A751809C135126C0AA21009B9F59B073692F6E4AD144C24C7F1539AF063D4696FB548EDB943B3A343397443449F9900075AF6AEAC479EE2081AD908D2AD61638C6C0719EACE6B424BD50
```

It then notes that lowercase `f` never appears and suggests base 59 as an alternative. Absence of a symbol in a finite sample does not by itself establish a smaller alphabet. A base-59 interpretation also needs an explicit symbol order and decoding convention. Neither proposal is presented here as a solved plaintext, and a byte-sized output is not proof of a particular encryption algorithm.

**Editorial checks on the printed transcription:** pages 49, 50, and 51 contain 80, 104, and 72 pairs respectively, totaling 256. The stated base-60 formula reproduces the entire displayed 512-character hexadecimal string. There are 59 distinct second characters, with `f` the only missing member of the proposed 60-symbol alphabet. These checks establish internal consistency of the text and conversion, not fidelity to the images or the correctness of the proposed encoding.

## 6. 2015: silence and a public denial

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29#Cicada_in_2015)

The authors report no new puzzle in January 2015 and describe imitations circulating instead. They record speculation that Liber Primus's incompleteness, sufficient recruitment, or abandonment might explain the silence. None of those explanations is established by the absence of a new puzzle.

The account characterizes a July statement as the year's only public communication from 3301. It dates the [tweet](https://twitter.com/1231507051321/status/625902337266204673) to July 27, 2015, at 10:35 p.m., without establishing the displayed time zone. The tweet links [Pastebin smRatr3D](http://pastebin.com/smRatr3D).

Reported message body, with whitespace normalized here; the disputed spacing is documented separately below:

```text
Some news organisations have recently claimed that "3301" is
tied to the illegal activities of a group that has claimed
responsibility for attacks against Planned Parenthood.

We do not engage in illegal activities.  We are not associated
with this group in any way, nor do condone their use of our
name, number, or symbolism.

3301
```

The displayed signed block has `Hash: SHA1` and `Version: GnuPG v1`. The article says verification against the previously used key proves its origin and calls it official. That verification has not been repeated here. The statement is a denial attributed to the message's author; it is not this project's independent finding about the attacks or any organization.

The authors further say that the group responsible for the attacks subsequently admitted no association with Cicada. This is a historical claim in the article, not independently substantiated in this document.

The account compares the wording with an earlier [2012 denial](https://uncovering-cicada.fandom.com/wiki/3301_accused_of_cyberterrorism), calling the 2015 text modified from it. Observations it highlights include the `organisations` spelling, use of `3301` rather than `Cicada 3301`, and the missing `we` in “nor do [we] condone.” It describes the spelling as a French “-ise” form; that linguistic characterization is the author's, and neither that label nor the spelling establishes authorship or nationality.

## 7. Whitespace sequences: reported hints and a source discrepancy

[Source comparison](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29#%22message.txt.asc%22_vs_%22Planned_Parenthood%22_Message)

The article argues that space-only lines and trailing spaces carry numeric sequences, contrasting them with ordinary line breaks in other messages such as the earlier Necrome denial. It presents screenshots, raw-text links, and diagrams replacing spaces with plus signs. These are separate representations with potentially different fidelity.

### 7.1 Reported 2014 sequence

The source's annotated version gives the following message layout. `[SP×n]` is this document's visible notation for the number of spaces claimed by the source, not characters in the original message. Ordinary internal word spacing is left as text:

```text
Hello.  Your enlightenment awaits you.[SP×2]
[SP×3]
[SP×5]ky2khlqdf7qdznac.onion[SP×7]
[SP×11]
We look forward to hearing from you.
[SP×13]
[SP×17]
Good luck.[SP×23]
[SP×29]
3301
[SP×31]
[SP×37]
```

Reported sequence:

```text
2, 3, 5, 7, 11, 13, 17, 23, 29, 31, 37
```

These are the primes through 37 with 19 omitted: eleven values rather than twelve. The source remarks that eleven is itself prime and says the missing 19 was unexplained. This arithmetic pattern can be recognized without establishing intentional encoding, the reason for omission, or the original whitespace.

The displayed signature metadata names `Hash: SHA1` and `GnuPG v1.4.11 (GNU/Linux)`. Source references for the underlying file are [Dropbox message.txt.asc](https://www.dropbox.com/sh/lkta4q921vliyuw/AABwIBrvR1AcQoTM3abMC3EPa/message.txt.asc?dl=0), [Pastebin 6M3s1FtC](http://pastebin.com/6M3s1FtC), and its [raw endpoint](http://pastebin.com/raw.php?i=6M3s1FtC).

### 7.2 Reported 2015 sequence

The article's prose and plus-sign diagram claim this arrangement:

```text
[SP×5]
Some news organisations have recently claimed that "3301" is
tied to the illegal activities of a group that has claimed
responsibility for attacks against Planned Parenthood.
[SP×3]
We do not engage in illegal activities.  We are not associated
with this group in any way, nor do condone their use of our
name, number, or symbolism.
[SP×2]
3301
[SP×5]
[SP×7]
```

Reported sequence: `5, 3, 2, 5, 7`, also concatenated by the authors as `53257`. They separate it into `532`, then the printed `3301`, then `57`, and speculate about the page numbering `0`–`57`. The individual values are prime, but the grouping and relevance are hypotheses rather than a demonstrated decoding.

The source links [the raw 2015 Pastebin](http://pastebin.com/raw.php?i=smRatr3D) for direct comparison.

### 7.3 What the consulted wiki actually renders

**Editorial check:** counting literal U+0020 spaces in the article's preformatted 2015 block labeled “Raw Text” does not reproduce the claimed sequence. The DOM text obtained on the consultation date contains:

| Position in that displayed block | Number of spaces |
| --- | --- |
| First whitespace-only line after `Hash: SHA1` | 1 |
| Next whitespace-only line, before the first paragraph | 4 |
| Between first and second paragraphs | 6 |
| Between second paragraph and `3301` | 5 |
| First line after `3301` | 8 |
| Second line after `3301` | 10 |

Those lines are numbered 3, 4, 8, 12, 14, and 15 when the opening `-----BEGIN PGP SIGNED MESSAGE-----` is line 1. The first line lies at the armor/body boundary and is not simply interchangeable with an ordinary content spacer. The second paragraph's first line also has a trailing space. Consequently, even defining which spaces belong to the hypothesized sequence needs an explicit rule.

This is a discrepancy between the wiki's present displayed text and its own explanatory claims. It does not establish the counts in the original Pastebin or delivered file, nor identify who changed anything or when. Both versions are retained; neither has been silently repaired to match the other.

### 7.4 Signature validity does not authenticate every space

**Additional technical context, not a claim from the wiki:** OpenPGP cleartext-signature processing removes trailing spaces and tabs from lines before hashing/signature verification. Therefore, a successful cleartext signature check would not by itself authenticate the counts of trailing spaces or spaces on otherwise blank lines. Leading spaces before non-whitespace content, such as before an onion address, are a different case and must not be conflated with trailing spaces. See [RFC 9580, sections 7.1–7.3](https://www.rfc-editor.org/rfc/rfc9580.html#section-7.1).

For this research, signed-message authenticity and preservation of the alleged whitespace channel are distinct questions. Original file provenance and byte-level comparisons remain necessary even if a message verifies successfully.

## 8. 2016: return to Liber Primus

[Source section](https://uncovering-cicada.fandom.com/wiki/What_Happened_Liber_Primus_%28Post_2014%29#Cicada_in_2016)

The authors again report no new puzzle at the start of January. Instead, an image was posted to Infotomb and linked from the [Twitter account's post](https://twitter.com/1231507051321/status/684596461628223488). The account describes Infotomb as a site established by a solver in earlier years to share images while preserving steganographic properties.

The narrative interprets the image as directing solvers back to unfinished Liber Primus and away from unverified imitations. It also includes judgments about the experience and behavior of people following other trails; those judgments are not evidence about any specific trail's authenticity.

The source says the motif previously described as a dendrite is an oak tree, citing a search for “dead oak tree clipart” and [this candidate image](http://www.clipartbest.com/cliparts/abc/y97/abcy97qTL.jpeg). It asserts that background blocks are compression noise rather than a QR code, and reports image dimensions of `563 × 569`, both prime. It interprets the tree, also found behind some Liber Primus pages, combined with a cicada as a likely starting-point hint.

The visual identification, compression explanation, exact image dimensions, and starting-point interpretation have not been independently reproduced here. Primality of the two printed dimensions can be checked, but that does not validate the image measurement or prove deliberate numeric design.

OutGuess reportedly recovered the same text with a signature. The displayed block has `Hash: SHA1`, a `GnuPG v1` signature header, and this body:

```text
Hello.

The path lies empty; epiphany seeks the devoted.

Liber Primus is the way.  Its words are the map, their
meaning is the road, and their numbers are the direction.

Seek and you will be found.


Good luck.

3301


Beware false paths.  Verify OpenPGP 7A35090F.
```

The eight-hex-digit key identifier `7A35090F` is preserved as part of the message; this document has not used it to retrieve or establish trust in a public key. The word/map, meaning/road, and number/direction associations remain puzzle text, not a complete algorithm.

The account ends by saying solvers returned to Liber Primus and that years had passed since a page was decrypted. No ending date is provided for that status statement. The [2017 signed-message page](https://uncovering-cicada.fandom.com/wiki/PGP_Signed_Message_April_2017) is linked in navigation but not developed in this narrative. Neither that message nor developments after the article's endpoint are independently surveyed here.

## 9. Questions and limits to carry into project planning

This is a register of evidence gaps and reproduction dependencies, not a set of accepted clues or a prioritized development plan.

| Detail | What remains uncertain or needs preserving |
| --- | --- |
| Delivery coverage | The account says all registered services received messages; no full recipient/capture set is provided |
| Delivery time | GMT prose and `+0200` logs do not directly agree |
| Request logs | Masked timestamps, `PP`, user-agent spellings, and E/S letter-number associations |
| Message identity | “Identical” recipient copies and `message.txt.asc` / `message.asc.txt` naming need original-file comparison |
| Website timeline | Last-Modified does not prove setup duration or intentional delay |
| Server identity | thttpd headers and Apache error footer differ |
| HTML details | Title 133, div ID 331, filename order, and unusual error text retained without assigning intent |
| Image archive fidelity | “Unmodified” is the source's description, not independently verified |
| Page sets | Decoration-based groups and cross-page routes are proposals |
| Visual labels | Dendrite/oak, mayfly, cuneiform, five-dot, and Möbius identifications need direct inspection |
| Numerical transcription | Underscore normalization loses separator/symbol distinctions |
| Page 56 exception | Exact rune index and prime-stream consumption must be kept separate from Vigenère resets |
| Page 56 target | Original hash transcription, algorithm, content bytes, and underlying service remain unestablished here |
| Page 57 arithmetic | Product matches, but gematria inputs and original metadata have not been reproduced |
| ASCII pairs | Conversion is internally consistent; glyph identity and original page fidelity remain unverified |
| Base 59 versus 60 | Missing lowercase f is an observation, not proof of either encoding |
| 2015 attribution | Signature claims and statements about other groups are reported, not independently adjudicated |
| 2015 clock time | Tweet time zone is not specified by the account |
| Whitespace channel | The present raw-text display and explanatory counts disagree |
| Whitespace authentication | Cleartext signatures do not preserve all trailing-space counts |
| Missing 19 / 53257 | Numeric associations are hypotheses without a demonstrated next step |
| 2016 image | Tree match, compression-noise explanation, dimensions, and start-point inference need the original |
| Present-day status | This narrative ends in 2016; a current status review is separate work |

### 9.1 Visual references not captured as original evidence

The following are image-page links actually present in the consulted article. Their legacy Wikia URLs are retained rather than silently replaced with guessed file destinations:

- [Page-set illustration](http://uncovering-cicada.wikia.com/wiki/File:1399181864285.png).
- [2015 tweet screenshot](http://uncovering-cicada.wikia.com/wiki/File:Screenshot_2015-11-17_09.35.05.png).
- [Signature-check illustration](http://uncovering-cicada.wikia.com/wiki/File:Kleogoodpgp.jpg).
- [2015 message comparison image](http://uncovering-cicada.wikia.com/wiki/File:Plannedp.jpg).
- [2014 message/spacing image](http://uncovering-cicada.wikia.com/wiki/File:Messagetxtasc.jpg).
- [2016 message image](http://uncovering-cicada.wikia.com/wiki/File:4gq25.jpg).

The article also links a [collection of ideas and suggestions](https://uncovering-cicada.fandom.com/wiki/Liber_Primus_Ideas_and_Suggestions). That collection was not imported into this account. Linked images, archives, source scripts, and original signed messages have not been acquired or independently authenticated as part of this task.

### 9.2 Verification performed for this document

- Read the article from “A Life Sign” through its 2016 ending in the browser, and inspected its preformatted text and link targets.
- Checked that the displayed page-56 hash joins to 128 hexadecimal characters, representing 512 bits of encoded data. Length alone does not establish its hash algorithm.
- Checked that `(269 − 1) mod 29 = 7` and the listed opening prime-minus-one shifts agree with the described sequence.
- Checked `1259 × 1031 × 1229 = 1,595,277,641`.
- Checked that the three ASCII blocks contain 80, 104, and 72 pairs, and that the stated base-60 convention reproduces the displayed 256-byte result.
- Checked the missing `f` observation against those pairs.
- Counted whitespace-only lines in the wiki's displayed 2015 raw block and recorded the discrepancy with the article's interpretation.
- Checked that 563 and 569 are prime.
- Did not perform original-image transcription, page decryption, OutGuess extraction, PGP verification, raw-file whitespace authentication, or live onion-service interaction.

## Appendix A. Image-reference HTML listing

The source displays spaces inside tag delimiters. This is a transcription of its presented listing, not a claim that the delivered HTTP body contained those literal spaces. The sequential 58 image lines are retained in full.

```html
   < html >
   < head >< title >133</ title ></ head >
   < body >
   < div id="331" >
   < img src="0.jpg" />< br />
   < img src="1.jpg" />< br />
   < img src="2.jpg" />< br />
   < img src="3.jpg" />< br />
   < img src="4.jpg" />< br />
   < img src="5.jpg" />< br />
   < img src="6.jpg" />< br />
   < img src="7.jpg" />< br />
   < img src="8.jpg" />< br />
   < img src="9.jpg" />< br />
   < img src="10.jpg" />< br />
   < img src="11.jpg" />< br />
   < img src="12.jpg" />< br />
   < img src="13.jpg" />< br />
   < img src="14.jpg" />< br />
   < img src="15.jpg" />< br />
   < img src="16.jpg" />< br />
   < img src="17.jpg" />< br />
   < img src="18.jpg" />< br />
   < img src="19.jpg" />< br />
   < img src="20.jpg" />< br />
   < img src="21.jpg" />< br />
   < img src="22.jpg" />< br />
   < img src="23.jpg" />< br />
   < img src="24.jpg" />< br />
   < img src="25.jpg" />< br />
   < img src="26.jpg" />< br />
   < img src="27.jpg" />< br />
   < img src="28.jpg" />< br />
   < img src="29.jpg" />< br />
   < img src="30.jpg" />< br />
   < img src="31.jpg" />< br />
   < img src="32.jpg" />< br />
   < img src="33.jpg" />< br />
   < img src="34.jpg" />< br />
   < img src="35.jpg" />< br />
   < img src="36.jpg" />< br />
   < img src="37.jpg" />< br />
   < img src="38.jpg" />< br />
   < img src="39.jpg" />< br />
   < img src="40.jpg" />< br />
   < img src="41.jpg" />< br />
   < img src="42.jpg" />< br />
   < img src="43.jpg" />< br />
   < img src="44.jpg" />< br />
   < img src="45.jpg" />< br />
   < img src="46.jpg" />< br />
   < img src="47.jpg" />< br />
   < img src="48.jpg" />< br />
   < img src="49.jpg" />< br />
   < img src="50.jpg" />< br />
   < img src="51.jpg" />< br />
   < img src="52.jpg" />< br />
   < img src="53.jpg" />< br />
   < img src="54.jpg" />< br />
   < img src="55.jpg" />< br />
   < img src="56.jpg" />< br />
   < img src="57.jpg" />< br />
   </ div >
   </ body >
   </ html >
```
