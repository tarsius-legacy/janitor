;;; janitor.el --- Fix other people's warnings  -*- lexical-binding:t -*-

;; Copyright (C) 2017-2022 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/emacsjanitors/janitor
;; Keywords: local

;; Package-Requires: (
;;     (emacs "28.1")
;;     (epkg "3.3.3")
;;     (ghub "3.5.5")
;;     (magit "3.3.0"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Fix other people's warnings.

;; Note that the first commit is named "Initial dump".  It will be
;; followed by commits described simply as "wip" and eventually I
;; will discard all that when I create the "Initial import".

;;; Code:

(require 'epkg)
(require 'ghub)
(require 'magit)

(defvar janitor-org "emacsjanitors")
(defvar janitor-remote "janitor")

(defvar janitor-github-token-scopes '(repo))

;;;###autoload
(defun janitor-clone (name)
  (interactive (list (epkg-read-package "Clone: " (thing-at-point 'filename))))
  (let* ((base "/tmp/janitor/")
         (repo (expand-file-name name base)))
    (unless (file-exists-p repo)
      (make-directory base t)
      (magit-call-git "clone" (oref (epkg name) url) repo))
    (let ((default-directory repo))
      (call-interactively 'janitor-setup-branch))))

;;;###autoload
(defun janitor-setup-branch (user name branch)
  (interactive
   (list (nth 3 (split-string (magit-get "remote.origin.url") "[@:/.]"))
         (oref (epkg (file-name-nondirectory
                      (directory-file-name (magit-toplevel))))
               upstream-name)
         (let ((current (magit-get-current-branch)))
           (read-string "Branch: " nil nil
                        (and (not (equal current "master")) current)))))
  (unless (cl-find-if (lambda (fork)
                        (equal (cdr (assq 'login (cdr (assq 'owner fork))))
                               janitor-org))
                      (ghub-get (format "/repos/%s/%s/forks" user name)
                                nil :auth 'janitor))
    (message "Forking...")
    (ghub-post (format "/repos/%s/%s/forks" user name)
               `((organization . ,janitor-org))
               :auth 'janitor)
    (ghub-wait (format "/repos/%s/%s" janitor-org name)
               nil :auth 'janitor)
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

;;;###autoload
(defun janitor-open-pull-request (user name branch)
  (interactive
   (list (nth 3 (split-string (magit-get "remote.origin.url") "[@:/.]"))
         (file-name-nondirectory (directory-file-name (magit-toplevel)))
         (magit-get-current-branch)))
  (browse-url (format "https://github.com/%s/%s/compare/master...%s:%s"
                      user name janitor-org branch)))

;;; _
(provide 'janitor)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; janitor.el ends here
