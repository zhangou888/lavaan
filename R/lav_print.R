## NOTE:
## round(1.2355, 3) = 1.236
## but
## round(1.2345, 3) = 1.234
##
## perhaps we should add 0.0005 or something to avoid this?

print.lavaan.data.frame <- function(x, ..., nd = 3L) {

    ROW.NAMES <- rownames(x)
    y <- as.data.frame(lapply(x, function(x) {
                              if(is.numeric(x)) round(x, nd) else x}))
    rownames(y) <- ROW.NAMES

    if(!is.null(attr(x, "header"))) {
        cat("\n", attr(x, "header"), "\n\n", sep = "")
    }

    print(y, ...)

    if(!is.null(attr(x, "footer"))) {
        cat("\n", attr(x, "footer"), "\n\n", sep = "")
    }

    invisible(x)
}

print.lavaan.list <- function(x, ...) {

    y <- unclass(x)
    attr(y, "header") <- NULL

    header <- attr(x, "header")
    if(!is.null(header)) {
        if(is.character(header)) {
            cat("\n", header, "\n\n", sep = "")
        } else {
            print(header); cat("\n")
        }
    }

    print(y, ...)
    invisible(x)
}


# prints only lower triangle of a symmetric matrix
print.lavaan.matrix.symmetric <- function(x, ..., nd = 3L) {
    # print only lower triangle of a symmetric matrix
    # this function was inspired by the `print.correlation' function
    # in package nlme
    y <- x; y <- unclass(y)
    ll <- lower.tri(x, diag=TRUE)
    y[ll] <- format(round(x[ll], digits=nd)); y[!ll] <- ""
    if (!is.null(colnames(x))) {
      colnames(y) <- abbreviate(colnames(x), minlength = nd + 3L)
    }
    print(y, ..., quote = FALSE)
    invisible(x)
}


print.lavaan.matrix <- function(x, ..., nd = 3L) {
    y <- unclass(x)
    if (!is.null(colnames(x))) {
      colnames(y) <- abbreviate(colnames(x), minlength = nd + 3L)
    }
    print( round(y, nd), ... )
    invisible(x)
}

print.lavaan.vector <- function(x, ..., nd = 3L) {
    y <- unclass(x)
    #if(!is.null(names(x))) {
    #    names(y) <- abbreviate(names(x), minlength = nd + 3)
    #}
    print( round(y, nd), ... )
    invisible(x)
}

print.lavaan.character <- function(x) {
    cat(x)
    invisible(x)
}

print.lavaan.parameterEstimates <- function(x, ..., nd = 3L) {

    # format for numeric values
    num.format  <- paste("%", max(8L, nd + 5L), ".", nd, "f", sep = "")
    char.format <- paste("%", max(8L, nd + 5L), "s", sep = "")

    # output sections
    GSECTIONS <- c("Latent Variables",
                   "Composites",
                   "Regressions",
                   "Covariances",
                   "Intercepts",
                   "Thresholds",
                   "Variances",
                   "Scales y*",
                   "Group Weight",
                   "R-Square")
    ASECTIONS <- c("Defined Parameters",
                   "Constraints")

    # header?
    header <- attr(x, "header")
    if(is.null(header)) {
        header <- FALSE
    }

    if(header) {
        cat("\nParameter Estimates:\n\n")

        # info about standard errors (if we have x$se only)
        # 1. information
        # 2. se
        # 3. bootstrap requested/successful draws
        if(!is.null(x$se)) {

            # container
            c1 <- c2 <- character(0L)

            if(attr(x, "se") != "bootstrap") {
                # 1.
                c1 <- c(c1, "Information")
                tmp.txt <- attr(x, "information")
                c2 <- c(c2, paste(toupper(substring(tmp.txt, 1, 1)),
                                  substring(tmp.txt, 2), sep = ""))

                # 2.
                if(attr(x, "information") %in% c("expected", "first.order") ||
                   attr(x, "observed.information") == "h1") {
                    c1 <- c(c1, "Information saturated (h1) model")
                    tmp.txt <- attr(x, "h1.information")
                    c2 <- c(c2, paste(toupper(substring(tmp.txt,1,1)),
                                      substring(tmp.txt, 2), sep = ""))
                }
                if(attr(x, "information") == "observed") {
                    c1 <- c(c1, "Observed information based on")
                    tmp.txt <- attr(x, "observed.information")
                    c2 <- c(c2, paste(toupper(substring(tmp.txt, 1, 1)),
                                      substring(tmp.txt, 2), sep = ""))
                }
            } # no bootstrap

            # 3.
            c1 <- c(c1, "Standard errors")
            tmp.txt <- attr(x, "se")
            c2 <- c(c2, paste(toupper(substring(tmp.txt, 1, 1)),
                                      substring(tmp.txt, 2), sep = ""))

            # 4.
            if(attr(x, "se") == "bootstrap" && !is.null(attr(x, "bootstrap"))) {
                c1 <- c(c1, "Number of requested bootstrap draws")
                c2 <- c(c2, attr(x, "bootstrap"))
                c1 <- c(c1, "Number of successful bootstrap draws")
                c2 <- c(c2, attr(x, "bootstrap.successful"))
            }

            # format c1/c2
            c1 <- format(c1, width = 38L)
            c2 <- format(c2,
                   width = 13L + max(0, (nd - 3L)) * 4L, justify = "right")

            # create character matrix
            M <- cbind(c1, c2, deparse.level = 0)
            colnames(M) <- rep("",  ncol(M))
            rownames(M) <- rep(" ", nrow(M))

            # print
            write.table(M, row.names = TRUE, col.names = FALSE, quote = FALSE)
        }
    }

    # number of groups
    if(is.null(x$group)) {
        ngroups <- 1L
        x$group <- rep(1L, length(x$lhs))
    } else {
        ngroups <- lav_partable_ngroups(x)
    }

    # number of levels
    if(is.null(x$level)) {
        nlevels <- 1L
        x$level <- rep(1L, length(x$lhs))
    } else {
        nlevels <- lav_partable_nlevels(x)
    }

    # block column
    if(is.null(x$block)) {
        x$block <- rep(1L, length(x$lhs))
    }

    # round to 3 digits after the decimal point
    y <- as.data.frame(
           lapply(x, function(x) {
               if(is.numeric(x)) {
                   sprintf(num.format, x)
               } else {
                   x
               }
           }),
           stringsAsFactors = FALSE)

    # always remove /block/level/group/op/rhs/label/exo columns
    y$op <- y$group <- y$rhs <- y$label <- y$exo <- NULL
    y$block <- y$level <- NULL
    y$efa <- NULL

    # if standardized, remove std.nox column (space reasons only)
    # unless, std.all is already removed
    if(!is.null(y$std.all)) {
        y$std.nox <- NULL
    }

    # convert to character matrix
    m <- as.matrix(format.data.frame(y, na.encode = FALSE,
                                         justify = "right"))

    # use empty row names
    rownames(m) <- rep("", nrow(m))

    # handle se == 0.0
    if(!is.null(x$se)) {
        se.idx <- which(x$se == 0)
        if(length(se.idx) > 0L) {
            m[se.idx, "se"] <- ""
            if(!is.null(x$z)) {
                m[se.idx, "z"] <- ""
            }
            if(!is.null(x$pvalue)) {
                m[se.idx, "pvalue"] <- ""
            }
            ## for lavaan.mi-class objects (semTools)
            if(!is.null(x$t)) {
                m[se.idx, "t"] <- ""
            }
            if(!is.null(x$df)) {
                m[se.idx, "df"] <- ""
            }
        }

        # handle se == NA
        se.idx <- which(is.na(x$se))
        if(length(se.idx) > 0L) {
            if(!is.null(x$z)) {
                m[se.idx, "z"] <- ""
            }
            if(!is.null(x$pvalue)) {
                m[se.idx, "pvalue"] <- ""
            }
            ## for lavaan.mi-class objects (semTools)
            if(!is.null(x$t)) {
                m[se.idx, "t"] <- ""
            }
            if(!is.null(x$df)) {
                m[se.idx, "df"] <- ""
            }
        }
    }

    # handle lower/upper boundary points
    if(!is.null(x$lower)) {
        b.idx <- which( abs(x$lower - x$est) < sqrt(.Machine$double.eps) &
                        is.finite(x$se) & x$se != 0.0)
        if(length(b.idx) > 0L && !is.null(x$pvalue)) {
            m[b.idx, "pvalue"] <- ""
            if(is.null(x$label)) {
                x$label <- rep("", length(x$lhs))
            }
            x$label[b.idx] <- ifelse(nchar(x$label[b.idx]) > 0L,
                                     paste(x$label[b.idx], "+lb", sep = ""),
                                     "lb")
        }
        # remove lower column
        m <- m[, colnames(m) != "lower"]
    }
    if(!is.null(x$upper)) {
        b.idx <- which( abs(x$upper - x$est) < sqrt(.Machine$double.eps) &
                        is.finite(x$se) & x$se != 0.0)
        if(length(b.idx) > 0L && !is.null(x$pvalue)) {
            m[b.idx, "pvalue"] <- ""
            if(is.null(x$label)) {
                x$label <- rep("", length(x$lhs))
            }
            x$label[b.idx] <- ifelse(nchar(x$label[b.idx]) > 0L,
                                     paste(x$label[b.idx], "+ub", sep = ""),
                                     "ub")
        }
        # remove upper column
        m <- m[, colnames(m) != "upper"]
    }


    # handle fmi
    if(!is.null(x$fmi)) {
        se.idx <- which(x$se == 0)
        if(length(se.idx) > 0L) {
            m[se.idx, "fmi"] <- ""
            ## for lavaan.mi-class objects (semTools)
            if (!is.null(x$riv)) m[se.idx, "riv"] <- ""
        }

        not.idx <- which(x$op %in% c(":=", "<", ">", "=="))
        if(length(not.idx) > 0L) {
            if(!is.null(x$fmi)) {
                m[not.idx, "fmi"] <- ""
                ## for lavaan.mi-class objects (semTools)
                if (!is.null(x$riv)) m[not.idx, "riv"] <- ""
            }
        }
    }

    # for blavaan, handle Post.SD and PSRF
    if(!is.null(x$Post.SD)) {
        se.idx <- which(x$Post.SD == 0)
        if(length(se.idx) > 0L) {
            m[se.idx, "Post.SD"] <- ""
            if(!is.null(x$psrf)) {
                m[se.idx, "psrf"] <- ""
            }
            if(!is.null(x$PSRF)) {
                m[se.idx, "PSRF"] <- ""
            }
        }

        # handle psrf for defined parameters
        not.idx <- which(x$op %in% c(":=", "<", ">", "=="))
        if(length(not.idx) > 0L) {
            if(!is.null(x$psrf)) {
                m[not.idx, "psrf"] <- ""
            }
            if(!is.null(x$PSRF)) {
                m[not.idx, "PSRF"] <- ""
            }
        }
    }

    # rename some column names
    colnames(m)[ colnames(m) ==    "lhs" ] <- ""
    colnames(m)[ colnames(m) ==     "op" ] <- ""
    colnames(m)[ colnames(m) ==    "rhs" ] <- ""
    colnames(m)[ colnames(m) ==    "est" ] <- "Estimate"
    colnames(m)[ colnames(m) ==     "se" ] <- "Std.Err"
    colnames(m)[ colnames(m) ==      "z" ] <- "z-value"
    colnames(m)[ colnames(m) == "pvalue" ] <- "P(>|z|)"
    colnames(m)[ colnames(m) == "std.lv" ] <- "Std.lv"
    colnames(m)[ colnames(m) == "std.all"] <- "Std.all"
    colnames(m)[ colnames(m) == "std.nox"] <- "Std.nox"
    colnames(m)[ colnames(m) == "prior"  ] <- "Prior"
    colnames(m)[ colnames(m) == "fmi"    ] <- "FMI"
    ## for lavaan.mi-class objects (semTools)
    if ("t" %in% colnames(m)) {
      colnames(m)[ colnames(m) == "t"      ] <- "t-value"
      colnames(m)[ colnames(m) == "P(>|z|)"] <- "P(>|t|)"
      colnames(m)[ colnames(m) == "riv"    ] <- "RIV"
    }

    # format column names
    colnames(m) <- sprintf(char.format, colnames(m))

    # exceptions for blavaan: Post.Mean (width = 9), Prior (width = 14)
    if(!is.null(x$Post.Mean)) {
        tmp <- gsub("[ \t]+", "", colnames(m), perl=TRUE)

        # reformat "Post.Mean" column
        col.idx <- which(tmp == "Post.Mean")
        if(length(col.idx) > 0L) {
            tmp.format <- paste("%", max(9, nd + 5), "s", sep="")
            colnames(m)[col.idx] <- sprintf(tmp.format, colnames(m)[col.idx])
            m[,col.idx] <- sprintf(tmp.format, m[,col.idx])
        }

        # reformat "Prior" column
        col.idx <- which(tmp == "Prior")
        if(length(col.idx) > 0L) {
            MAX <- max( nchar( m[,col.idx] ) ) + 1L
            tmp.format <- paste("%", max(MAX, nd + 5), "s", sep="")
            colnames(m)[col.idx] <- sprintf(tmp.format, colnames(m)[col.idx])
            m[,col.idx] <- sprintf(tmp.format, m[,col.idx])
        }
    }

    b <- 0L
    # group-specific sections
    for(g in 1:ngroups) {

        # group header
        if(ngroups > 1L) {
            group.label <- attr(x, "group.label")
            cat("\n\n")
            cat("Group ", g, " [", group.label[g], "]:\n", sep="")
        }

        for(l in 1:nlevels) {

            # block number
            b <- b + 1L

            # ov/lv names
            ov.names <- lavNames(x, "ov", block = b)
            lv.names <- lavNames(x, "lv", block = b)

            # level header
            if(nlevels > 1L) {
                level.label <- attr(x, "level.label")
                cat("\n\n")
                cat("Level ", l, " [", level.label[l], "]:\n", sep="")
            }

            # group-specific sections
            for(s in GSECTIONS) {
                if(s == "Latent Variables") {
                        row.idx <- which( x$op == "=~" & !x$lhs %in% ov.names &
                                      x$block == b)
                    if(length(row.idx) == 0L) next
                    m[row.idx,1] <- .makeNames(x$rhs[row.idx], x$label[row.idx])
                } else if(s == "Composites") {
                    row.idx <- which( x$op == "<~" & x$block == b)
                    if(length(row.idx) == 0L) next
                    m[row.idx,1] <- .makeNames(x$rhs[row.idx], x$label[row.idx])
                } else if(s == "Regressions") {
                    row.idx <- which( x$op == "~" & x$block == b)
                    if(length(row.idx) == 0L) next
                    m[row.idx,1] <- .makeNames(x$rhs[row.idx], x$label[row.idx])
                } else if(s == "Covariances") {
                    row.idx <- which(x$op == "~~" & x$lhs != x$rhs & !x$exo &
                                     x$block == b)
                    if(length(row.idx) == 0L) next
                    # make distinction between residual and plain
                    y.names <- unique( c(lavNames(x, "eqs.y"),
                                         lavNames(x, "ov.ind"),
                                         lavNames(x, "lv.ind")) )
                    PREFIX <- rep("", length(row.idx))
                    PREFIX[ x$rhs[row.idx] %in% y.names ] <- "  ."
                    m[row.idx,1] <- .makeNames(x$rhs[row.idx], x$label[row.idx],
                                               PREFIX = PREFIX)
                    #m[row.idx,1] <- .makeNames(x$rhs[row.idx], x$label[row.idx])
                } else if(s == "Intercepts") {
                    row.idx <- which(x$op == "~1" & !x$exo & x$block == b)
                    if(length(row.idx) == 0L) next
                    # make distinction between intercepts and means
                    y.names <- unique( c(lavNames(x, "eqs.y"),
                                         lavNames(x, "ov.ind"),
                                         lavNames(x, "lv.ind")) )
                    PREFIX <- rep("", length(row.idx))
                    PREFIX[ x$lhs[row.idx] %in% y.names ] <- "  ."
                        m[row.idx,1] <- .makeNames(x$lhs[row.idx], x$label[row.idx],
                                               PREFIX = PREFIX)
                    #m[row.idx,1] <- .makeNames(x$lhs[row.idx], x$label[row.idx])
                } else if(s == "Thresholds") {
                    row.idx <- which(x$op == "|" & x$block == b)
                    if(length(row.idx) == 0L) next
                    m[row.idx,1] <- .makeNames(paste(x$lhs[row.idx], "|",
                        x$rhs[row.idx], sep=""), x$label[row.idx])
                } else if(s == "Variances") {
                    row.idx <- which(x$op == "~~" & x$lhs == x$rhs & !x$exo &
                                     x$block == b)
                    if(length(row.idx) == 0L) next
                    # make distinction between residual and plain
                    y.names <- unique( c(lavNames(x, "eqs.y"),
                                         lavNames(x, "ov.ind"),
                                         lavNames(x, "lv.ind")) )
                    PREFIX <- rep("", length(row.idx))
                    PREFIX[ x$rhs[row.idx] %in% y.names ] <- "  ."
                    m[row.idx,1] <- .makeNames(x$rhs[row.idx], x$label[row.idx],
                                               PREFIX = PREFIX)
                } else if(s == "Scales y*") {
                    row.idx <- which(x$op == "~*~" & x$block == b)
                    if(length(row.idx) == 0L) next
                    m[row.idx,1] <- .makeNames(x$rhs[row.idx], x$label[row.idx])
                } else if(s == "Group Weight") {
                        row.idx <- which(x$lhs == "group" & x$op == "%" & x$block == b)
                    if(length(row.idx) == 0L) next
                    m[row.idx,1] <- .makeNames(x$rhs[row.idx], x$label[row.idx])
                } else if(s == "R-Square") {
                        row.idx <- which(x$op == "r2" & x$block == b)
                    if(length(row.idx) == 0L) next
                    m[row.idx,1] <- .makeNames(x$rhs[row.idx], x$label[row.idx])
                } else {
                        row.idx <- integer(0L)
                }

                # do we need special formatting for this section?
                # three types:
                #  - regular (nothing to do, except row/colnames)
                #  - R-square
                #  - Latent Variables (and Composites), Regressions and Covariances
                #    'bundle' the output per lhs element

                # bundling
                if(s %in% c("Latent Variables", "Composites",
                            "Regressions", "Covariances")) {
                    nel <- length(row.idx)
                    M <- matrix("", nrow = nel*2, ncol = ncol(m))
                    colnames(M) <- colnames(m)
                    rownames(M) <- rep("", NROW(M))
                    #colnames(M)[1] <- sprintf("%-17s", paste(s, ":", sep = ""))
                    if(is.null(x$efa)) {
                        LHS <- paste(x$lhs[row.idx], x$op[row.idx])
                    } else {
                        LHS <- paste(x$lhs[row.idx], x$op[row.idx],
                                     x$efa[row.idx])
                    }
                    lhs.idx <- seq(1, nel*2L, 2L)
                    rhs.idx <- seq(1, nel*2L, 2L) + 1L
                    if(s == "Covariances") {
                        # make distinction between residual and plain
                        y.names <- unique( c(lavNames(x, "eqs.y"),
                                             lavNames(x, "ov.ind"),
                                             lavNames(x, "lv.ind")) )
                            PREFIX <- rep("", length(row.idx))
                        PREFIX[ x$lhs[row.idx] %in% y.names ] <- "."
                    } else {
                        PREFIX <- rep("", length(LHS))
                    }
                    M[lhs.idx, 1] <- sprintf("%1s%-15s", PREFIX, LHS)
                    M[rhs.idx,  ] <- m[row.idx,]
                    # avoid duplicated LHS labels
                        if(nel > 1L) {
                        del.idx <- integer(0)
                        old.lhs <- ""
                        for(i in 1:nel) {
                            if(LHS[i] == old.lhs) {
                                del.idx <- c(del.idx, lhs.idx[i])
                            }
                            old.lhs <- LHS[i]
                        }
                            if(length(del.idx) > 0L) {
                            M <- M[-del.idx,,drop=FALSE]
                        }
                    }
                    cat("\n", s, ":\n", sep = "")
                        #cat("\n")
                    print(M, quote = FALSE)

                # R-square
                } else if(s == "R-Square") {
                    M <- m[row.idx,1:2,drop=FALSE]
                    colnames(M) <- colnames(m)[1:2]
                    rownames(M) <- rep("", NROW(M))
                    #colnames(M)[1] <- sprintf("%-17s", paste(s, ":", sep = ""))
                    cat("\n", s, ":\n", sep = "")
                    #cat("\n")
                    print(M, quote = FALSE)

                # Regular
                } else {
                    #M <- rbind(matrix("", nrow = 1L, ncol = ncol(m)),
                    #           m[row.idx,])
                    M <- m[row.idx,,drop=FALSE]
                    colnames(M) <- colnames(m)
                    rownames(M) <- rep("", NROW(M))
                    #colnames(M)[1] <- sprintf("%-17s", paste(s, ":", sep = ""))
                    cat("\n", s, ":\n", sep = "")
                    #cat("\n")
                    print(M, quote = FALSE)
                }
            } # GSECTIONS

        } # levels

    } # groups

    # asections
    for(s in ASECTIONS) {
        if(s == "Defined Parameters") {
            row.idx <- which(x$op == ":=")
            m[row.idx,1] <- .makeNames(x$lhs[row.idx], "")
            M <- m[row.idx,,drop=FALSE]
            colnames(M) <- colnames(m)
        } else if(s == "Constraints") {
            row.idx <- which(x$op %in% c("==", "<", ">"))
            if(length(row.idx) == 0) next
            m[row.idx,1] <- .makeConNames(x$lhs[row.idx], x$op[row.idx],
                                          x$rhs[row.idx], nd = nd)
            m[row.idx,2] <- sprintf(num.format, abs(x$est[row.idx]))
            M <- m[row.idx,1:2,drop=FALSE]
            colnames(M) <- c("", sprintf(char.format, "|Slack|"))
        } else {
            row.idx <- integer(0L)
        }

        if(length(row.idx) == 0L) {
            next
        }

        rownames(M) <- rep("", NROW(M))
        #colnames(M)[1] <- sprintf("%-17s", paste(s, ":", sep = ""))
        #cat("\n")
        cat("\n", s, ":\n", sep = "")
        print(M, quote = FALSE)
    }
    cat("\n")

    invisible(m)
}

.makeNames <- function(NAMES, LABELS, PREFIX = NULL) {

    W <- 14
    if(is.null(PREFIX)) {
        PREFIX <- rep("", length(NAMES))
    }

    multiB <- FALSE
    if(any(nchar(NAMES) != nchar(NAMES, "bytes")))
        multiB <- TRUE
    if(any(nchar(LABELS) != nchar(LABELS, "bytes")))
        multiB <- TRUE
    # labels?
    l.idx <- which(nchar(LABELS) > 0L)
    if(length(l.idx) > 0L) {
        if(!multiB) {
            LABELS <- abbreviate(LABELS, 4)
            LABELS[l.idx] <- paste(" (", LABELS[l.idx], ")", sep="")
            MAX.L <- max(nchar(LABELS))
            NAMES <- abbreviate(NAMES, minlength = (W - MAX.L),
                                strict = TRUE)
        } else {
            # do not abbreviate anything (eg in multi-byte locales)
            MAX.L <- 4L
        }
        NAMES <- sprintf(paste("%-", (W - MAX.L), "s%", MAX.L, "s",
                               sep=""), NAMES, LABELS)
    } else {
        if(!multiB) {
            NAMES <- abbreviate(NAMES, minlength = W, strict = TRUE)
        } else {
            NAMES <- sprintf(paste("%-", W, "s", sep=""), NAMES)
        }
    }

    char.format <- paste("%3s%-", W, "s", sep = "")
    sprintf(char.format, PREFIX, NAMES)
}

.makeConNames <- function(lhs, op, rhs, nd) {

    nd <- max(nd, 3)
    W <- 41 + (nd - 3)*3

    nel <- length(lhs)
    if(length(nel) == 0L) return(character(0))
    NAMES <- character(nel)
    for(i in 1:nel) {
        if(rhs[i] == "0" && op[i] == ">") {
            con.string <- paste(lhs[i], " - 0", sep="")
        } else if(rhs[i] == "0" && op[i] == "<") {
            con.string <- paste(rhs[i], " - (", lhs[i], ")", sep="")
        } else if(rhs[i] != "0" && op[i] == ">") {
            con.string <- paste(lhs[i], " - (", rhs[i], ")", sep="")
        } else if(rhs[i] != "0" && op[i] == "<") {
            con.string <- paste(rhs[i], " - (", lhs[i], ")", sep="")
        } else if(rhs[i] == "0" && op[i] == "==") {
            con.string <- paste(lhs[i], " - 0", sep="")
        } else if(rhs[i] != "0" && op[i] == "==") {
            con.string <- paste(lhs[i], " - (", rhs[i], ")", sep="")
        }
        con.string <- abbreviate(con.string, W, strict = TRUE)
        char.format <- paste("   %-", W, "s", sep = "")
        NAMES[i] <- sprintf(char.format, con.string)
    }

    NAMES
}

summary.lavaan.fsr <- function(object, ...) {

    dotdotdot <- list(...)
    if(!is.null(dotdotdot$nd)) {
        nd <- dotdotdot$nd
    } else {
        nd <- 3L
    }

    print.lavaan.fsr(x = object, nd = nd, mm = TRUE, struc = TRUE)
}

print.lavaan.fsr <- function(x, ..., nd = 3L, mm = FALSE, struc = FALSE) {

    y <- unclass(x)

    # print header
    if(!is.null(y$header)) {
        cat(y$header)
        cat("\n")
    }

    if(mm && !is.null(y$MM.FIT)) {
        cat("\n")
        nblocks <- length(y$MM.FIT)
        for(b in seq_len(nblocks)) {
            cat("Measurement block for latent variable(s):",
                paste(lavNames(y$MM.FIT[[b]], "lv")), "\n")

            # fit measures?
            b.options <- lavInspect(y$MM.FIT[[b]], "options")
            if(!(length(b.options$test) == 1L && b.options$test == "none")) {
                cat("\n")
                print(fitMeasures(y$MM.FIT[[b]], c("chisq", "df", "pvalue", "cfi", "rmsea", "srmr")))
            }

            # parameter estimates
            PE <- parameterEstimates(y$MM.FIT[[b]], ci = FALSE,
                                     output = "text", header = TRUE)
            print.lavaan.parameterEstimates(PE, ..., nd = nd)
            cat("\n")
        }
    }

    # print PE
    if(struc) {
        cat("Structural Part\n")
        cat("\n")
        #print.lavaan.parameterEstimates(y$PE, ..., nd = nd)

        lav_object_print_short_summary(y$STRUC.FIT)
        FIT <- fitMeasures(y$STRUC.FIT, fit.measures="default")
        if(FIT["df"] > 0) {
            print.lavaan.fitMeasures( FIT )
        }
    }
    PE <- parameterEstimates(y$STRUC.FIT, ci = FALSE,
                             remove.eq = FALSE, remove.system.eq = TRUE,
                             remove.ineq = FALSE, remove.def = FALSE,
                             remove.nonfree = FALSE,
                             output = "text", header = TRUE)
    print.lavaan.parameterEstimates(PE, ..., nd = nd)

    invisible(y)
}


# print warnings/errors in a consistent way
# YR 12 July 2018

lav_txt2message <- function(txt, header = "lavaan WARNING:",
                            footer = "", txt.width = 70L, shift = 3L) {
    # make sure we only have a single string
    txt <- paste(txt, collapse = "")

    # split the txt in little chunks
    chunks <- strsplit(txt, "\\s+", fixed = FALSE)[[1]]

    # chunk size (number of characters)
    chunk.size <- nchar(chunks)

    # remove empty chunks (needed?)
    empty.idx <- which(chunk.size == 0)
    if(length(empty.idx) > 0L) {
        chunks <- chunks[-empty.idx]
        chunk.size <- chunk.size[-empty.idx]
    }

    # insert "\n" so the txt never gets wider than txt.width
    num.lines <- floor((sum(chunk.size) + length(chunk.size))/txt.width + 0.5)
    target <- character(num.lines)

    line.size <- shift
    line.num <- 1L
    start.chunk <- 1L
    end.chunck <- 1L
    for(ch in seq_len( length(chunks) )) {
        line.size <- line.size + chunk.size[ch] + 1L
        if(line.size > txt.width) {
            end.chunk <- ch - 1L
            target[line.num] <- paste(c(rep(" ", (shift-1)),
                                        chunks[ start.chunk:end.chunk ]),
                                      collapse = " ")
            line.num <- line.num + 1L
            start.chunk <- ch
            line.size <- shift + chunk.size[ch] + 1L
        }
    }
    # last line
    target[line.num] <- paste(c(rep(" ", (shift-1)),
                              chunks[ start.chunk:ch ]), collapse = " ")

    body <- paste(target, collapse = "\n")
    if(nchar(footer) == 0L) {
       out <- paste(c(header, body), collapse = "\n")
    } else {
       out <- paste(c(header, body, footer), collapse = "\n")
    }

    out
}

