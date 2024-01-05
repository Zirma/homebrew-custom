# Original version from homebrew-science, with update for v2.21

class CalculixCcx < Formula
  desc "Three-Dimensional Finite Element Solver"
  homepage "http://www.calculix.de/"
  url "http://www.dhondt.de/ccx_2.21.src.tar.bz2"
  version "2.21"
  sha256 "52a20ef7216c6e2de75eae460539915640e3140ec4a2f631a9301e01eda605ad"

  depends_on "pkg-config" => :build
  depends_on "arpack"
  depends_on "gcc" if OS.mac? # for gfortran
  depends_on "gfortran"
  depends_on "openblas"
  depends_on "lapack"
  depends_on "hwloc"
  depends_on "metis"
  depends_on "scotch"

  resource "test" do
    url "http://www.dhondt.de/ccx_2.21.test.tar.bz2"
    version "2.21"
    sha256 "094a0a2ec324fc6f937a96e932b488f48f31ad8d5d1186cd14437e6dc3e599ea"
  end

  resource "doc" do
    url "http://www.dhondt.de/ccx_2.21.htm.tar.bz2"
    version "2.21"
    sha256 "1ed21976ba2188d334fe0b5917cf75b8065b9c0b939e6bd35bd98ed57a725ba2"
  end

  resource "spooles" do
    # The spooles library is not currently maintained and so would not make a
    # good brew candidate. Instead it will be static linked to ccx.
    url "http://www.netlib.org/linalg/spooles/spooles.2.2.tgz"
    sha256 "a84559a0e987a1e423055ef4fdf3035d55b65bbe4bf915efaa1a35bef7f8c5dd"
  end

  patch :DATA

  def install
    (buildpath/"spooles").install resource("spooles")

    # Patch spooles library
    inreplace "spooles/Make.inc", "/usr/lang-4.0/bin/cc", ENV.cc
    inreplace "spooles/Tree/src/makeGlobalLib", "drawTree.c", "tree.c"

    # Build serial spooles library
    system "make", "-C", "spooles", "lib"

    # Extend library with multi-threading (MT) subroutines
    system "make", "-C", "spooles/MT/src", "makeLib"

    # Buid Calculix ccx
    cflags = %w[-O2 -I../../spooles -DARCH=Linux -DSPOOLES -DARPACK -DMATRIXSTORAGE]
    libs = ["$(DIR)/spooles.a", "$(shell pkg-config --libs arpack)"]
    # ARPACK uses Accelerate on macOS
    libs << "-framework accelerate"
    args = ["CC=#{ENV.cc}",
            "FC=gfortran",
            "CFLAGS=#{cflags.join(" ")}",
            "DIR=../../spooles",
            "LIBS=#{libs.join(" ")}"]
    target = Pathname.new("ccx_2.17/src/ccx_2.17")
    system "make", "-C", target.dirname, target.basename, *args
    bin.install target

    (buildpath/"test").install resource("test")
    pkgshare.install Dir["test/ccx_2.17/test/*"]

    (buildpath/"doc").install resource("doc")
    doc.install Dir["doc/ccx_2.17/doc/ccx/*"]
  end

  test do
    cp "#{pkgshare}/spring1.inp", testpath
    system "#{bin}/ccx_2.17", "spring1"
  end
end

__END__
diff --git a/ccx_2.17/src/Makefile b/ccx_2.17/src/Makefile
index 97ce9d1..632a617 100755
--- a/ccx_2.17/src/Makefile
+++ b/ccx_2.17/src/Makefile
@@ -1,6 +1,6 @@
 
 CFLAGS = -Wall -O2  -I ../../../SPOOLES.2.2 -DARCH="Linux" -DSPOOLES -DARPACK -DMATRIXSTORAGE -DNETWORKOUT
-FFLAGS = -Wall -O2
+FFLAGS = -std=legacy -O2
 
 CC=cc
 FC=gfortran
@@ -25,8 +25,8 @@ LIBS = \
 	../../../ARPACK/libarpack_INTEL.a \
        -lpthread -lm -lc
 
-ccx_2.17: $(OCCXMAIN) ccx_2.17.a  $(LIBS)
-	./date.pl; $(CC) $(CFLAGS) -c ccx_2.17.c; $(FC)  -Wall -O2 -o $@ $(OCCXMAIN) ccx_2.17.a $(LIBS)
+ccx_2.17: $(OCCXMAIN) ccx_2.17.a
+	./date.pl; $(CC) $(CFLAGS) -c ccx_2.17.c; $(FC) $(FFLAGS) -o $@ $(OCCXMAIN) ccx_2.17.a $(LIBS)
 
 ccx_2.17.a: $(OCCXF) $(OCCXC)
 	ar vr $@ $?