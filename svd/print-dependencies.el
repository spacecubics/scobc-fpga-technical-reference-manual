(unless (= 1 (length command-line-args-left))
  (user-error "Usage: emacs --script %s FILE" (file-name-nondirectory load-file-name)))

(require 'org)
(find-file-read-only (car command-line-args-left))
(org-element-map (org-element-parse-buffer) 'keyword
  (lambda (kw)
    (let ((key (org-element-property :key kw)))
      (when (string= key "INCLUDE")
        (princ (format "%s\n" (string-trim (org-element-property :value kw) "\"" "\"")))))))
