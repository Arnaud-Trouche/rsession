#help: First-order local optimization algorithm<br/>http://en.wikipedia.org/wiki/Gradient_descent
#tags: optimization
#options: yminimization='false'; iterations='100'; delta='1'; epsilon='0.01'; target='Inf'
#input: x=list(min=0,max=1)
#output: y=0.99

#' constructor and initializer of R session
GradientDescent <- function(opts) {
  gradientdescent = new.env()

  gradientdescent$yminimization <- isTRUE(as.logical(opts$yminimization))
  gradientdescent$iterations <- as.integer(opts$iterations)
  gradientdescent$delta <- as.numeric(opts$delta)
  gradientdescent$epsilon <- as.numeric(opts$epsilon)
  gradientdescent$target <- as.numeric(opts$target)
  if (!gradientdescent$yminimization){
    if (isTRUE(gradientdescent$target == -Inf)) {
      gradientdescent$target = Inf
    }
  }
  if (gradientdescent$yminimization){
    if (isTRUE(gradientdescent$target == Inf)){
      gradientdescent$target = -Inf
    }
  }
  gradientdescent$i = 0

  return(gradientdescent)
}

#' first design building. All variables are set in [min,max]
#' @param input variables description (min/max, properties, ...)
#' @param output values of interest description
getInitialDesign <- function(algorithm,input,output) {
  algorithm$i = 0
  algorithm$input <- input
  d = length(input)
  x = askfinitedifferences(rep(0.5,d),algorithm$epsilon)
  names(x) <- names(input)
  return(from01(x,algorithm$input))
}

#' iterated design building.
#' @param X data frame of current doe variables
#' @param Y data frame of current results
#' @return data frame or matrix of next doe step
getNextDesign <- function(algorithm,X,Y) {
  #normalize delta factor of gradient by fun range
  if (algorithm$i == 1) {
    algorithm$delta = algorithm$delta / (max(Y[,1])-min(Y[,1]))
  }
  if (algorithm$i > algorithm$iterations) { return(); }

  if (algorithm$yminimization) {
    if (min(Y[,1]) < algorithm$target) { return(); }
  } else {
    if (max(Y[,1]) > algorithm$target) { return(); }
  }

  names(X) <- names(algorithm$input)
  X = to01(X,algorithm$input)
  d = ncol(X)
  n = nrow(X)

  prevXn = X[(n-d):n,] 
  prevYn = Y[(n-d):n,1]
  if (algorithm$i > 1) {
    if (algorithm$yminimization) {
      if (Y[n-d,1] > Y[n-d-d,1]) {
        algorithm$delta <- algorithm$delta / 2
        prevXn = X[(n-d-d-1):(n-d-1),] #as.matrix(X[(n-d-d-1):(n-d-1),])
        prevYn = Y[(n-d-d-1):(n-d-1),1] #as.array(Y[(n-d-d-1):(n-d-1),1])
      }
    }
    if (!algorithm$yminimization) {
      if (Y[n-d,1] < Y[n-d-d,1]) {
        algorithm$delta <- algorithm$delta / 2
        prevXn = X[(n-d-d-1):(n-d-1),] #as.matrix(X[(n-d-d-1):(n-d-1),])
        prevYn = Y[(n-d-d-1):(n-d-1),1] #as.array(Y[(n-d-d-1):(n-d-1),1])
      }
    }
  }
  if (d==1) { prevXn = matrix(prevXn,ncol=d) }

  grad = gradient(prevXn,prevYn)
  # grad = grad / sqrt(sum(grad * grad))

  if (algorithm$yminimization) {
    xnext = prevXn[1,] - grad * algorithm$delta
  } else {
    xnext = prevXn[1,] + grad * algorithm$delta
  }
  xnext=t(xnext)

  for (t in 1:d) {
    while(xnext[t] > 1.0 | xnext[t] < 0){
      if (xnext[t] > 1.0) {
        xnext[t] = 1.0 - xnext[t];
      }
      if (xnext[t] < 0.0) {
        xnext[t] = 0.0 - xnext[t];
      }
    }
  }

  algorithm$i <- algorithm$i+1

  x = askfinitedifferences(xnext,algorithm$epsilon)
  names(x) <- names(algorithm$input)

  return(from01(x,algorithm$input))
}

#' final analysis. Return HTML string
#' @param X data frame of doe variables
#' @param Y data frame of  results
#' @return HTML string of analysis
displayResults <- function(algorithm,X,Y) {
  Y = Y[,1]
  m = min(Y)
  m.ix = which.min(Y)
  m.ix = m.ix[1]
  x = X[m.ix,] 

  resolution <- 600
  d = dim(X)[2]

  if (algorithm$yminimization) {
    red = (as.matrix(Y)-min(Y))/(max(Y)-min(Y))
  } else {
    red = (max(Y)-as.matrix(Y))/(max(Y)-min(Y))
  }
  if(d>1) {
    algorithm$files <- paste0("pairs_",algorithm$i-1,".png",sep="")
    png(file=algorithm$files,bg="transparent",height=resolution,width = resolution)
    pairs(cbind(X,Y),col=rgb(r=red,g=0,b=1-red)) 
    dev.off()
  } else {
    algorithm$files <- paste0("plot_",algorithm$i-1,".png",sep="")
    png(file=algorithm$files,bg="transparent",height=resolution,width = resolution)
    plot(x=X[,1],y=Y,xlab=names(X),ylab=names(Y),col=rgb(r=red,g=0,b=1-red))
    dev.off()
  }

  if (algorithm$yminimization) {
    html=paste0("<HTML name='minimum'>minimum is ",m,
                " found at ",
                paste0(paste(names(X),'=',x, collapse=';')),
                "<br/><img src='",
                algorithm$files,
                "' width='",resolution,"' height='",resolution,
                "'/></HTML>")

    m=paste("<min>",m,"</min>")
    argmin=paste("<argmin>[",paste(collapse=',',x),"]</argmin>")

    return(paste(html,m,argmin,collapse=';'))
  } else {
    html=paste0("<HTML name='maximum'>maximum is ",m,
                " found at ",
                paste0(paste(names(X),'=',x, collapse=';')),
                "<br/><img src='",
                algorithm$files,
                "' width='",resolution,"' height='",resolution,
                "'/></HTML>")

    m=paste("<max>",m,"</max>")
    argmax=paste("<argmax>[",paste(collapse=',',x),"]</argmax>")

    return(paste(html,m,argmax,collapse=';'))
  }
}

panel.vec <- function(x, y , col, Y, d, ...) {
  #points(x,y,col=col)
  n = length(x)/(d+1)
  for (i in 1:n) {
    n0 = 1+(i-1)*(d+1)
    x0 = x[n0]
    y0 = y[n0]
    for (j in 1:d) {
      if (x[n0+j] != x0) {
        dx = (Y[n0]-Y[n0+j])/(max(Y)-min(Y))
        #break;
      }
    }
    for (j in 1:d) {
      if (y[n0+j] != y0) {
        dy = (Y[n0]-Y[n0+j])/(max(Y)-min(Y))
        #break;
      }
    }
    points(x=x0,y=y0,col=col[n0],pch=20)
    lines(x=c(x0,x0+dx),y=c(y0,y0+dy),col=col[n0])
    if (exists("x0p")) {
      lines(x=c(x0p,x0),y=c(y0p,y0),col=col[n0],lty=3)
    }
    x0p=x0
    y0p=y0
  }

}

#' temporary analysis. Return HTML string
#' @param X data frame of doe variables
#' @param Y data frame of  results
#' @returnType String
#' @return HTML string of analysis
displayResultsTmp <- function(algorithm,X,Y) {
  displayResults(algorithm,X,Y)
}

###################################################################

askfinitedifferences <- function(x,epsilon) {
  xd <- matrix(x,nrow=1);
  for (i in 1:length(x)) {
    xdi <- as.array(x);
    if (xdi[i] + epsilon > 1.0) {
      xdi[i] <- xdi[i] - epsilon;
    } else {
      xdi[i] <- xdi[i] + epsilon;
    }
    # xd <- rbind(xd,xdi,deparse.level = 0)
    xd <- rbind(xd,matrix(xdi,nrow=1))
}
  return(xd)
}

gradient <- function(xd,yd) {
  d = ncol(xd)
  grad = rep(0,d)
  for (i in 1:d) {
    grad[i] = (yd[i+1] - yd[1]) / (xd[i+1,i] - xd[1,i])
  }
  return(grad)
}

from01 = function(X, inp) {
  nX = names(X)
  for (i in 1:ncol(X)) {
    namei = nX[i]
    X[,i] = X[,i] * (inp[[ namei ]]$max-inp[[ namei ]]$min) + inp[[ namei ]]$min
  }
  return(X)
}

to01 = function(X, inp) {
  nX = names(X)
  for (i in 1:ncol(X)) {
    namei = nX[i]
    X[,i] = (X[,i] - inp[[ namei ]]$min) / (inp[[ namei ]]$max-inp[[ namei ]]$min)
  }
  return(X)
}

##############################################################################################
# @test
# f <- function(X) matrix(apply(X,1,function (x) {
#     x1 <- x[1] * 15 - 5
#     x2 <- x[2] * 15
#     (x2 - 5/(4 * pi^2) * (x1^2) + 5/pi * x1 - 6)^2 + 10 * (1 - 1/(8 * pi)) * cos(x1) + 10
# }),ncol=1)
# f1 = function(x) f(cbind(.5,x))
#
# options = list(iterations = 10, delta = 0.1, epsilon = 0.01, target=0)
# gd = algorithm(options)
#
# # X0 = getInitialDesign(gd, input=list(x1=list(min=0,max=1),x2=list(min=0,max=1)), NULL)
# # Y0 = f(X0)
# X0 = getInitialDesign(gd, input=list(x2=list(min=0,max=1)), NULL)
# Y0 = f1(X0)
# Xi = X0
# Yi = Y0
#
# finished = FALSE
# while (!finished) {
#     Xj = getNextDesign(gd,Xi,Yi)
#     if (is.null(Xj) | length(Xj) == 0) {
#         finished = TRUE
#     } else {
#         Yj = f1(Xj)
#         Xi = rbind(Xi,Xj)
#         Yi = rbind(Yi,Yj)
#     }
# }
#
# print(displayResults(gd,Xi,Yi))
