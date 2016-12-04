#!/bin/bash
set -e

ROOTFOLDER=$HOME/tmp
QREPO=$ROOTFOLDER/qrepo

echo "####################"
echo "setup"
echo "####################"
rm -rf $QREPO
make install_qpr
make install_qpm
make install_qp
echo "success"

echo "####################"
echo "test repo creation"
echo "####################"
if ! q qpr.q create $QREPO -q; then
	echo "qpr repo creation failed"
	exit 1
else
	echo "success\n"
fi

echo "####################"
echo "test adding libraries"
echo "####################"
for lib in testlib testlib_new testlib2 testlib3 testlibBadQVersion testlibWindowsOnly testlibDepsBadQ; do
	if ! q qpr.q add $PWD/testPackages/$lib -loc file://$QREPO -q; then
		echo "qpr add library to repo failed"
		exit 1
	else
		echo "$lib success"
	fi
done

echo "testing that qpr doesn't add a bad library"
if q qpr.q add testPackages/badlib -loc file://$QREPO -q; then
	echo "qpr add malformed library to repo succeeded"
	exit 1
else
	echo "success"
fi

echo "####################"
echo "test using QREPO env variable"
echo "####################"
export QREPO=file://$QREPO
if ! q qpr.q add $PWD/testPackages/testlib -q; then
	echo "qpr using QREPO env variable failed"
	exit 1
else
	echo "success"
fi

echo "####################"
echo "test lists"
echo "####################"
export QREPO=file://$QREPO
if ! q qpr.q list -q; then
	echo "listing repos failed"
	exit 1
else
	echo "success"
fi

echo "####################"
echo "test install library"
echo "####################"
export QREPO=file://$QREPO
if ! q qpm.q install testlib -q; then
	echo "package install failed"
	exit 1
else
	echo "success"
fi

echo "####################"
echo "test install library failure due to os"
echo "####################"
export QREPO=file://$QREPO
if q qpm.q install testlibWindowsOnly -q; then
	echo "package install succeeded when it should have failed"
	exit 1
else
	echo "success"
fi

echo "####################"
echo "test install library failure due to q version"
echo "####################"
export QREPO=file://$QREPO
if q qpm.q install testlibBadQVersion -q; then
	echo "package install succeeded when it should have failed"
	exit 1
else
	echo "success"
fi

echo "####################"
echo "test install library failure where dependency is incompatible with q"
echo "####################"
export QREPO=file://$QREPO
if q qpm.q install testlibDepsBadQ -q; then
	echo "package install succeeded when it should have failed"
	exit 1
else
	echo "success"
fi

echo "####################"
echo "test uninstall library"
echo "####################"
export QREPO=file://$QREPO
for lib in testlib testlib2 testlib3; do
	if ! q qpm.q uninstall $lib -q; then
		echo "package uninstall failed"
		exit 1
	else
		echo "success"
	fi
done
