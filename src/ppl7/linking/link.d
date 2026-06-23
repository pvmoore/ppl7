module ppl7.linking.link;

import ppl7.all;

/**
 * Call the external linker to create the executable
 */
bool linkProject(Project project) {
    return msLink(project);
}
