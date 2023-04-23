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
         :base-extension "png")
        ("css"
         :base-directory "./css"
         :publishing-directory "_readthedocs/html/css/"
         :publishing-function org-publish-attachment
         :base-extension "css")
        ("js"
         :base-directory "./js"
         :publishing-directory "_readthedocs/html/js/"
         :publishing-function org-publish-attachment
         :base-extension "js")))

(org-publish-all t)
