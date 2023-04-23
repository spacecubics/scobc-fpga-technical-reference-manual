(require 'org)
(require 'ox-publish)

(setq org-publish-project-alist
      '(("orgs"
         :base-directory "./"
         :publishing-directory "_readthedocs/html/"
         :publishing-function org-html-publish-to-html
         :exclude "*.org"
         :include ("index.org")
         :section-numbers t
         :with-sub-superscript nil
         :with-toc t)
        ("images"
         :base-directory "./images"
         :publishing-directory "_readthedocs/html/images/"
         :publishing-function org-publish-attachment
         :base-extension "png")))

(org-publish-all t)
