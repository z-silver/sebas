#!/usr/bin/env janet

(def- request-header
  '{:main :request

    :octet 1
    :char (range "\0\x7f")
    :upalpha (range "AZ")
    :loalpha (range "az")
    :alpha :a
    :digit :d
    :ctl (+ (range "\0\x1f") "\x7f")
    :cr "\r"
    :lf "\n"
    :sp " "
    :ht "\t"
    :quote "\""

    :crlf (* :cr :lf)

    :lws (replace (* (? :crlf) (some (+ :sp :ht))) " ")

    :text (+ :lws (* (! :ctl) :octet))

    :hex :h

    :token (some (* (! :ctl) (! :separator) :char))
    :separator (+ (set "()<>@,;:\\\"/[]?={}") :sp :ht)

    :comment (* "(" (any (+ :ctext :quoted-pair :comment)) ")")
    :ctext (* (! (set "()")) :text)

    :quoted-string (* "\"" (any (+ :qdtext :quoted-pair)) "\"")
    :qdtext (* (! "\"") :text)

    :quoted-pair (* "\\" :char)

    :http-version (group (* "HTTP/" '(some :digit) "." '(some :digit)))

    :http-date (+ :rfc1123-date :rfc850-date :asctime-date)
    :rfc1123-date (* :wkday "," :sp :date1 :sp :time :sp "GMT")
    :rfc850-date (* :weekday "," :sp :date2 :sp :time :sp "GMT")
    :asctime-date (* :wkday :sp :date3 :sp :time :sp "GMT")
    :date1 (* (2 :digit) :sp :month :sp (4 :digit))
    :date2 (* (2 :digit) "-" :month "-" (2 :digit))
    :date3 (* :month :sp (+ :digit :sp) :digit)
    :time (* (2 :digit) ":" (2 :digit) ":" (2 :digit))
    :wkday (+ "Mon" "Tue" "Wed" "Thu" "Fri" "Sat" "Sun")
    :weekday (+ "Monday" "Tuesday" "Wednesday" "Thursday" "Friday" "Saturday" "Sunday")
    :month (+ "Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec")

    :delta-seconds (some :digit)

    :charset :token

    :content-coding :token

    :transfer-coding (+ "chunked" :transfer-extension)
    :transfer-extension (* :token (any (* ";" :parameter)))

    :parameter (* :attribute "=" :value)
    :attribute :token
    :value (+ :token :quoted-string)

    :media-type (* :type "/" :subtype (any (* ";" :parameter)))
    :type :token
    :subtype :token

    :product (* :token (? (* "/" :product-version)))
    :product-version :token

    :qvalue (+ (* "0" (? (* "." (at-most 3 :digit))))
              (* "1" (? (* "." (at-most 3 "0")))))

    :language-tag (* :primary-tag (any (* "-" :subtag)))
    :primary-tag (between 1 8 :alpha)
    :subtag (between 1 8 :alpha)

    :entity-tag (* (? :weak) :opaque-tag)
    :opaque-tag :quoted-string

    :range-unit (+ :bytes-unit :other-range-unit)
    :bytes-unit "bytes"
    :other-range-unit :token

    :request (* (any :crlf)
               :request-line
               (group (any (* (+ :general-header
                                :request-header
                                :entity-header)
                             :crlf)))
               :crlf
               ':message-body)
    :message-body (any :octet)

    :general-header :message-header
    :request-header :message-header
    :entity-header :message-header

    :message-header (group (* ':field-name ":" (drop (any :lws)) ':field-value))
    :field-name :token
    :field-value (any (+ :field-content :lws))
    :field-content (+ (any (+ :token :separator :quoted-string))
                     (any :text))

    :request-line (* ':method  :sp ':request-uri :sp :http-version :crlf)
    :method (+ "OPTIONS"
              "GET"
              "HEAD"
              "POST"
              "PUT"
              "DELETE"
              "TRACE"
              "CONNECT"
              :extension-method)
    :extension-method :token

    :request-uri (some (* (! :ctl) (! :sp) :char))})

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
