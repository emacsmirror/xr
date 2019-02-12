;;; xr-test.el --- Tests for xr.el                   -*- lexical-binding: t -*-

;; Copyright (C) 2019 Free Software Foundation, Inc.

;; Author: Mattias Engdegård <mattiase@acm.org>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


(require 'xr)
(require 'ert)


(ert-deftest xr-basic ()
  (should (equal (xr "a\\$b\\\\c\\[\\]\\q")
                 "a$b\\c[]q"))
  (should (equal (xr "\\(?:ab\\|c*d\\)?")
                 '(opt (or "ab" (seq (zero-or-more "c") "d")))))
  (should (equal (xr ".+")
                 '(one-or-more nonl)))
  )

(ert-deftest xr-repeat ()
  (should (equal (xr "\\(?:x?y\\)\\{3\\}")
                 '(= 3 (opt "x") "y")))
  (should (equal (xr "\\(?:x?y\\)\\{3,8\\}")
                 '(repeat 3 8 (opt "x") "y")))
  (should (equal (xr "\\(?:x?y\\)\\{3,\\}")
                     '(>= 3 (opt "x") "y")))
  (should (equal (xr "\\(?:x?y\\)\\{,8\\}")
                 '(repeat 0 8 (opt "x") "y")))
  (should (equal (xr "\\(?:xy\\)\\{4,4\\}")
                 '(= 4 "xy")))
  (should (equal (xr "a\\{,\\}")
                 '(zero-or-more "a")))
  (should (equal (xr "a\\{0\\}")
                 '(repeat 0 0 "a")))
  (should (equal (xr "a\\{0,\\}")
                 '(zero-or-more "a")))
  (should (equal (xr "a\\{0,0\\}")
                 '(repeat 0 0 "a")))
  (should (equal (xr "a\\{\\}")
                 '(repeat 0 0 "a")))
  (should (equal (xr "a\\{,1\\}")
                 '(repeat 0 1 "a")))
  (should (equal (xr "a\\{1,\\}")
                 '(>= 1 "a")))
  )

(ert-deftest xr-backref ()
  (should (equal (xr "\\(ab\\)\\(?3:cd\\)\\1\\3")
                 '(seq (group "ab") (group-n 3 "cd") (backref 1) (backref 3))))
  (should (equal (xr "\\01")
                 "01"))
  (should-error (xr "\\(?abc\\)"))
  (should-error (xr "\\(?2\\)"))
  (should-error (xr "\\(?0:xy\\)"))
  (should (equal (xr "\\(?29:xy\\)")
                 '(group-n 29 "xy")))
  )

(ert-deftest xr-misc ()
  (should (equal (xr "^.\\w\\W\\`\\'\\=\\b\\B\\<\\>\\_<\\_>$")
                 '(seq bol nonl wordchar not-wordchar bos eos point
                       word-boundary not-word-boundary bow eow
                       symbol-start symbol-end eol)))
  (should-error (xr "\\_a"))
  )

(ert-deftest xr-syntax ()
  (should (equal (xr "\\s-\\s \\sw\\sW\\s_\\s.\\s(\\s)\\s\"")
                 '(seq (syntax whitespace) (syntax whitespace) (syntax word)
                       (syntax word)
                       (syntax symbol) (syntax punctuation)
                       (syntax open-parenthesis) (syntax close-parenthesis)
                       (syntax string-quote))))
  (should (equal (xr "\\s\\\\s/\\s$\\s'\\s<\\s>\\s!\\s|")
                 '(seq (syntax escape) (syntax character-quote)
                       (syntax paired-delimiter) (syntax expression-prefix)
                       (syntax comment-start) (syntax comment-end)
                       (syntax comment-delimiter) (syntax string-delimiter))))
  (should (equal (xr "\\S-\\S<")
                 '(seq (not (syntax whitespace))
                       (not (syntax comment-start)))))
  )

(ert-deftest xr-category ()
  (should (equal (xr "\\c0\\c1\\c2\\c3\\c4\\c5\\c6\\c7\\c8\\c9\\c<\\c>")
                 '(seq (category consonant) (category base-vowel)
                       (category upper-diacritical-mark)
                       (category lower-diacritical-mark)
                       (category tone-mark) (category symbol) (category digit)
                       (category vowel-modifying-diacritical-mark)
                       (category vowel-sign) (category semivowel-lower)
                       (category not-at-end-of-line)
                       (category not-at-beginning-of-line))))
  (should (equal (xr "\\cA\\cC\\cG\\cH\\cI\\cK\\cN\\cY\\c^")
          '(seq (category alpha-numeric-two-byte) (category chinese-two-byte)
                (category greek-two-byte) (category japanese-hiragana-two-byte)
                (category indian-two-byte)
                (category japanese-katakana-two-byte)
                (category korean-hangul-two-byte) (category cyrillic-two-byte)
                (category combining-diacritic))))
  (should (equal (xr "\\ca\\cb\\cc\\ce\\cg\\ch\\ci\\cj\\ck\\cl\\co\\cq\\cr")
          '(seq (category ascii) (category arabic) (category chinese)
                (category ethiopic) (category greek) (category korean)
                (category indian)  (category japanese)
                (category japanese-katakana) (category latin) (category lao)
                (category tibetan) (category japanese-roman))))
  (should (equal (xr "\\ct\\cv\\cw\\cy\\c|")
                 '(seq (category thai) (category vietnamese) (category hebrew)
                       (category cyrillic) (category can-break))))
  (should (equal (xr "\\C2\\C^")
                 '(seq (not (category upper-diacritical-mark))
                       (not (category combining-diacritic)))))
  (should (equal (xr "\\cR\\C.\\cL\\C ")
		 '(seq (category strong-right-to-left)
		       (not (category base)) (category strong-left-to-right)
		       (not (category space-for-indent)))))
  (should (equal (xr "\\c%\\C+")
                 '(seq (regexp "\\c%") (regexp "\\C+"))))
  )

(ert-deftest xr-lazy ()
  (should (equal (xr "\\(?:a.\\)*?")
                 '(*? "a" nonl)))
  (should (equal (xr "\\(?:a.\\)+?")
                 '(+? "a" nonl)))
  (should (equal (xr "\\(?:a.\\)??")
                 '(?? "a" nonl)))
  (should (equal (xr "\\(?:.\\(a+\\(?:b+?c*\\)?\\)??\\)*")
                 '(zero-or-more
                   nonl
                   (?? (group (one-or-more "a")
                              (opt (+? "b")
                                   (zero-or-more "c")))))))
  )

(ert-deftest xr-char-classes ()
  (should (equal (xr "[[:alnum:][:blank:]][[:alpha:]][[:cntrl:][:digit:]]")
                 '(seq (any alnum blank) alpha (any cntrl digit))))
  (should (equal (xr "[^[:lower:][:punct:]][^[:space:]]")
                 '(seq (not (any lower punct)) (not space))))
  (should (equal (xr "^[a-z]*")
                 '(seq bol (zero-or-more (any "a-z")))))
  (should (equal (xr "some[.]thing")
                 "some.thing"))
  (should (equal (xr "[^]-c]")
                 '(not (any "]-c"))))
  (should (equal (xr "[-^]")
                 '(any "-" "^")))
  (should (equal (xr "[a-z-+/*%0-4[:xdigit:]]")
                 '(any "a-z" "-" "+/*%" "0-4" xdigit)))
  (should (equal (xr "[^]A-Za-z-]*")
                 '(zero-or-more (not (any "]" "A-Za-z" "-")))))
  (should (equal (xr "[+*%A-Ka-k0-3${-}]")
                 '(any "+*%" "A-Ka-k0-3" "$" "{-}")))
  )

(ert-deftest xr-empty ()
  (should (equal (xr "")
                 ""))
  (should (equal (xr "a\\|")
                 '(or "a" "")))
  (should (equal (xr "\\|a")
                 '(or "" "a")))
  (should (equal (xr "a\\|\\|b")
                 '(or "a" "" "b")))
  )

(ert-deftest xr-anything ()
  (should (equal (xr "\\(?:.\\|\n\\)?\\(\n\\|.\\)*")
                 '(seq (opt anything) (zero-or-more (group anything)))))
  )

(ert-deftest xr-real ()
  (should (equal (xr "\\*\\*\\* EOOH \\*\\*\\*\n")
                 "*** EOOH ***\n"))
  (should (equal (xr "\\<\\(catch\\|finally\\)\\>[^_]")
                 '(seq bow (group (or "catch" "finally")) eow
                       (not (any "_")))))
  (should (equal (xr "[ \t\n]*:\\([^:]+\\|$\\)")
                 '(seq (zero-or-more (any " \t\n")) ":"
                       (group (or (one-or-more (not (any ":")))
                                  eol)))))
  )

(ert-deftest xr-edge-cases ()
  (should (equal (xr "^a^b\\(?:^c^\\|^d^\\|e^\\)^")
                 '(seq bol "a^b" (or (seq bol "c^") (seq bol "d^") "e^") "^")))
  (should (equal (xr "$a$b\\(?:$c$\\|$d$\\|$e$\\)$")
                 '(seq "$a$b" (or (seq "$c" eol) (seq "$d" eol) (seq "$e" eol))
                       eol)))
  (should (equal (xr "*a\\|*b\\(*c\\)")
                 '(or "*a" (seq "*b" (group "*c")))))
  (should (equal (xr "+a\\|+b\\(+c\\)")
                 '(or "+a" (seq "+b" (group "+c")))))
  (should (equal (xr "?a\\|?b\\(^?c\\)")
                 '(or "?a" (seq "?b" (group bol "?c")))))
  (should (equal (xr "^**")
                 '(seq bol (zero-or-more "*"))))
  (should (equal (xr "^+")
                 '(seq bol "+")))
  (should (equal (xr "^?")
                 '(seq bol "?")))
  (should (equal (xr "*?a\\|^??b")
                 '(or (seq (opt "*") "a") (seq bol (opt "?") "b"))))
  (should (equal (xr "^\\{xy")
                 '(seq bol "{xy")))
  (should (equal (xr "\\{2,3\\}")
                 "{2,3}"))
  )

(ert-deftest xr-simplify ()
  (should (equal (xr "a\\(?:b?\\(?:c.\\)d*\\)e")
                 '(seq "a" (opt "b") "c" nonl (zero-or-more "d") "e")))
  (should (equal (xr "a\\(?:b\\(?:c.d\\)e\\)f")
                 '(seq "abc" nonl "def")))
  )

(ert-deftest xr-pretty ()
  (should (equal (xr-pp-rx-to-str "A\e\r\n\t\0 \x7f\x80\ B\xff\x02")
                 "\"A\\e\\r\\n\\t\\x00 \\x7f\\200B\\xff\\x02\"\n"))
  (should (equal (xr-pp-rx-to-str '(?? nonl))
                 "(?? nonl)\n"))
  (should (equal (xr-pp-rx-to-str '(repeat 1 63 "a"))
                 "(repeat 1 63 \"a\")\n"))
  )

(provide 'xr-test)

;;; xr-test.el ends here
