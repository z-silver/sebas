#!/usr/bin/env janet

(def- request-header
  '{:main (* (any :crlf)
             :start-line
             (group (any :http-header))
             :crlf
             ':body)
    :lw (set " \t\0")
    :lw* (any :lw)
    :lw+ (some :lw)
    :body (any 1)
    :attribute (some (* (! (+ :crlf ":")) 1))
    :http-header (group (* :lw* ':attribute ":" :lw+ '(to :crlf) :crlf))
    :method :w+
    :version (+ "0.9" "1.0" "1.1")
    :start-line (* :lw* ':method  :lw+ "/" :lw+ "HTTP/" ':version :lw* :crlf)
    :crlf "\r\n"})

(defn handler
  [stream]
  (defer (:close stream)
    (def buf @"")
    (net/read stream 8192 buf 10)
    (pp (peg/match request-header buf))
    (net/write stream "HTTP/1.1 404 NOT FOUND\r\n")))

(def test
  "GET / HTTP/1.1\r\ntype: yay\r\n\r\nsomebody once told me the world was gonna roll me")

(defn main [& args]
  (def server (net/listen "127.0.0.1" "8000"))
  (forever
    (ev/call handler (net/accept server))))
