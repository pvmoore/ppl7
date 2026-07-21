module ppl7.resolving.resolve_variable;

import ppl7.all;

void resolveVariable(Variable n, ResolveState state) {
    if(n.isResolved()) {
        fold(n, state);
    }
}
