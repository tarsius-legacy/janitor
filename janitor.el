;;; janitor.el --- fix other people's warnings

;; Copyright (C) 2017  Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://gitlab.com/emacsjanitors/janitor

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Fix other peoples warnings.

;; Note that the first commit is named "Initial dump".  It will be
;; followed by commits described simply as "wip" and eventually I
;; will discard all that when I create the "Initial import".

;;; Code:

(require 'ghub)
(require 'magit)

(defvar janitor-org "emacsjanitors")
(defvar janitor-remote "janitor")

(defun janitor-setup-branch (user name branch)
  (interactive
   (list (nth 3 (split-string (magit-get "remote.origin.url") "[@:/.]"))
         (file-name-nondirectory (directory-file-name (magit-toplevel)))
         (let ((current (magit-get-current-branch)))
           (read-string "Branch: " nil nil
                        (and (not (equal current "master")) current)))))
  (unless (cl-find-if (lambda (fork)
                        (equal (cdr (assq 'login (cdr (assq 'owner fork))))
                               janitor-org))
                      (ghub-get (format "/repos/%s/%s/forks" user name)))
    (message "Forking...")
    (ghub-post (format "/repos/%s/%s/forks" user name)
               nil `((organization . ,janitor-org)))
    (ghub-wait (format "/repos/%s/%s" janitor-org name))
    (message "Forking...done"))
  (unless (magit-remote-p janitor-remote)
    (message "Adding remote...")
    (magit-call-git "remote" "add" janitor-remote
                    (format "git@github.com:%s/%s.git" janitor-org name))
    (message "Adding remote...done"))
  (unless (equal branch (magit-get-current-branch))
    (if (magit-branch-p branch)
        (magit-call-git "checkout" branch)
      (let ((inhibit-magit-refresh t))
        (magit-branch-spinoff branch))))
  (magit-set janitor-remote "branch" branch "pushRemote")
  (magit-refresh))

(defun janitor-open-pull-request (user name branch)
  (interactive
   (list (nth 3 (split-string (magit-get "remote.origin.url") "[@:/.]"))
         (file-name-nondirectory (directory-file-name (magit-toplevel)))
         (magit-get-current-branch)))
  (browse-url (format "https://github.com/%s/%s/compare/master...%s:%s"
                      user name janitor-org branch)))

(provide 'janitor)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; janitor.el ends here
