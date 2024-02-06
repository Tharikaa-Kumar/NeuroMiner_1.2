if ~isDesktop
    setuppip
    pkg = "numpy scipy scikit-learn pandas sdv uuid";
    pipinstall(pkg)
    pipshow(pkg)
end