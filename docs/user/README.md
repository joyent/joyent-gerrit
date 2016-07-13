<!--
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
-->

<!--
    Copyright 2016 Joyent, Inc.
-->

# cr.joyent.us new user instructions

[cr.joyent.us](https://cr.joyent.us) is the Joyent Code Review server, running
the [Gerrit Code Review](https://www.gerritcodereview.com/) tool.

## Quick overview

Gerrit is a combination of two pieces:

* a Git server.  You submit code for review using `git(1)`, just like you're
  used to.  The main difference is that instead of pushing changes directly to
  `master`, you push them to a special reference that creates a new Change
  inside Gerrit.
* a web interface.  You typically add reviewers, submit feedback, vote on
  changes, approve changes, and finally integrate changes into master all
  through the web UI.

There's also a REST API and an ssh-based CLI that support many of the same
operations as the web interface.

There are a few other things to know about Gerrit:

* Gerrit formalizes the notion of a Change and patchset.  See the quick start
  below.
* The process of "integrating" (or "landing") a change (either by merge, rebase,
  fast-forward, or cherry-pick) is called **submitting** it.  This might be
  confusing if you think of "submitting a change for review".  **In Gerrit,
  submitting a change refers to integrating it into master.**
* Gerrit enforces that each patchset consists of exactly one commit.  This
  matches our policy for pushes, although we do sometimes review changes that
  aren't yet squashed.  You can still do this with Gerrit!  See the FAQ for
  details.
* Gerrit also formalizes the notion of approval with a voting system.  It uses
  numeric values, but these don't get added together.  See the FAQ for details.


## About these docs

In this document:

* [New user instructions](#new-user-instructions)
* [Quick start: using Gerrit for code review](#quick-start-using-gerrit-for-code-review)
* [Using cr.joyent.us with an existing local workspace](#using-crjoyentus-with-an-existing-local-workspace)
* [Importing an existing GitHub repository](#importing-an-existing-github-repository)
* [Creating a new repository](#creating-a-new-repository)
* [Merging from upstream repositories](#merging-from-upstream-repositories)
* [FAQ](#faq)
    * [What do I have to do right now?](#what-do-i-have-to-do-right-now)
    * [Which repositories are going to use cr.joyent.us?](#which-repositories-are-going-to-use-crjoyentus)
    * [Which repositories have already been transitioned to cr.joyent.us?](#which-repositories-have-already-been-transitioned-to-crjoyentus)
    * [After a repository has been imported into cr.joyent.us, where's the repository of record? Is it Gerrit or GitHub?](#after-a-repository-has-been-imported-into-crjoyentus-wheres-the-repository-of-record--is-it-gerrit-or-github)
    * [What do we do if someone accidentally pushes to GitHub instead of Gerrit?](#what-do-we-do-if-someone-accidentally-pushes-to-github-instead-of-gerrit)
    * [Can we enforce that people don't accidentally push to GitHub instead of Gerrit?](#can-we-enforce-that-people-dont-accidentally-push-to-github-instead-of-gerrit)
    * [What are the exact policies around code review and voting?](#what-are-the-exact-policies-around-code-review-and-voting)
    * [How will we handle changes that need to be kept secret (e.g., security fixes)?](#how-will-we-handle-changes-that-need-to-be-kept-secret-eg-security-fixes)
    * [If Gerrit requires a single commmit per change, how can I maintain multiple local commits?](#if-gerrit-requires-a-single-commmit-per-change-how-can-i-maintain-multiple-local-commits)
    * [Who can become an administrator?](#who-can-become-an-administrator)

For more help with the **mechanics of using Gerrit**, including specific steps
or configuration, check out the [Gerrit User
Guide](https://cr.joyent.us/Documentation/intro-user.html).  **We have one major
exception to the standard Gerrit workflow:** rather than putting Change-Id into
commit messages, we have people push new changes to [the special
refs/changes/...
references](https://cr.joyent.us/Documentation/access-control.html#_refs_changes).
This is shown in the examples below.

There's a separate [cr.joyent.us operator guide](../operator/README.md) for
those interested in helping run cr.joyent.us.

If you want to reach out to a person, contact an administrator.  You can [list
the administrators](https://cr.joyent.us/#/admin/groups/1,members) in Gerrit.
The new user instructions below will mention a few places where you need an
administrator to take action to get your account set up.


## New user instructions

1. Navigate to [https://cr.joyent.us](https://cr.joyent.us).
2. Click the "Sign in" link and **grant access to our Gerrit GitHub
   application**.  This is currently only used for authentication to the Gerrit
   web UI.
3. Next, **add a public key** for ssh access to the Gerrit repositories.  Back
   in the Gerrit web interface, click your name in the top-right, then click
   Settings.  On the left, click "SSH Public Keys" and add an ssh public key.
4. Next, **register and confirm your email address** so that you can receive
   email notifications.  From the same screen where you added public keys, click
   "Contact Information" on the left to register your email address.  Follow
   the instructions to verify your address.
5. **Test out ssh access.**  Your ssh username should be the same as your GitHub
   account name.  You can confirm this in the Gerrit web UI by clicking the
   "Profile" link on the left (from the same screen where you added your email
   address).  The "username" field should match your GitHub account name.
   
   You should be able to log in like this (with your username):

       $ ssh davepacheco@cr.joyent.us
       
         ****    Welcome to Gerrit Code Review    ****
       
         Hi David Pacheco, you have successfully connected over SSH.
       
         Unfortunately, interactive shells are disabled.
         To clone a hosted Git repository, use:
       
         git clone ssh://davepacheco@cr.joyent.us/REPOSITORY_NAME.git
       
       Connection to cr.joyent.us closed.

  If you have trouble with this, see "Getting help" above.

* Have an administrator add your account to the appropriate groups inside
  Gerrit.  See "Getting help" above.

Now that you're ready to start using Gerrit, check out the [Gerrit User
Guide](https://cr.joyent.us/Documentation/intro-user.html).


## Quick start: using Gerrit for code review

These instructions assume you have already followed the "New user instructions"
above.

Let's walk through an example.  I've got a repository on cr.joyent.us called
`my-playground`.  First, I clone it:

    dap@sharptooth ~ $ git clone --origin=cr ssh://davepacheco@cr.joyent.us/my-playground.git
    Cloning into 'my-playground'...
    remote: Counting objects: 2, done
    remote: Finding sources: 100% (2/2)
    remote: Total 2 (delta 0), reused 0 (delta 0)
    Receiving objects: 100% (2/2), done.

Now, let me add a README and commit that:

    dap@sharptooth my-playground $ vim README.md
    dap@sharptooth my-playground $ git add README.md 
    dap@sharptooth my-playground $ git commit -m "add initial README"
    [master 95a7c80] add initial README
     1 file changed, 1 insertion(+)
     create mode 100644 README.md

Now I'm ready to send this out for review.  Gerrit first-classes the idea of a
single logical change to the repository, and that's called a **Change** (of
course).  In Gerrit, a Change encapsulates multiple revisions of the work as
well as the review and automated verification process around the change.  I can
create a new change from my commit by pushing to the magic branch
`refs/for/master`:

    dap@sharptooth my-playground $ git push cr HEAD:refs/for/master
    Counting objects: 4, done.
    Writing objects: 100% (3/3), 266 bytes, done.
    Total 3 (delta 0), reused 0 (delta 0)
    remote: Processing changes: new: 1, refs: 1, done    
    remote: 
    remote: New Changes:
    remote:   https://cr.joyent.us/12 add initial README
    remote: 
    To ssh://davepacheco@cr.joyent.us/my-playground.git
     * [new branch]      HEAD -> refs/for/master

Gerrit gave me back a URL that I can use to refer to this Change.  It also
assigns it a ChangeId.  (There's a long ChangeId and a short one.  We can
generally use the short one.  In this case, that's `12`.)

Reviewers can be automatically notified and they can leave their feedback in the
UI.  We won't go through that process here.

Once I've got feedback, I might make some changes to the README:

    dap@sharptooth my-playground $ vim README.md 
    dap@sharptooth my-playground $ git add README.md 
    dap@sharptooth my-playground $ git commit -m "forgot to add content"
    [master f6eb4be] forgot to add content
     1 file changed, 2 insertions(+)

At this point, I want to upload a new revision of the same Change.  Gerrit calls
each revision a **PatchSet**.  In order to submit it, I need to squash my
change:

    dap@sharptooth my-playground $ git rebase -i HEAD^^
    [detached HEAD 920280c] initial README; forgot to add content
     1 file changed, 3 insertions(+)
     create mode 100644 README.md
    Successfully rebased and updated refs/heads/master.

And then I push that to the magical reference `refs/changes/12` (because this is
a new PatchSet for Change 12):

    dap@sharptooth my-playground $ git push cr HEAD:refs/changes/12
    Counting objects: 4, done.
    Delta compression using up to 8 threads.
    Compressing objects: 100% (2/2), done.
    Writing objects: 100% (3/3), 316 bytes, done.
    Total 3 (delta 0), reused 0 (delta 0)
    remote: Processing changes: updated: 1, refs: 1, done    
    remote: 
    remote: Updated Changes:
    remote:   https://cr.joyent.us/12 initial README; forgot to add content
    remote: 
    To ssh://davepacheco@cr.joyent.us/my-playground.git
     * [new branch]      HEAD -> refs/changes/12

The Change's URL is the same as it was.  Now if you visit it, you'll see the
latest patchset by default.  You can also view diffs against the previous
patchset (or any previous patchset).

When we're satisfied with everything, we're ready to **submit the change**,
which is (somewhat confusingly) the Gerrit terminology for integrating the
change into "master".  To enable this, the change needs at least one "+2" vote.
Even with a "+2", Gerrit will only allow changes to be integrated that can be
fast-forwarded onto "master".  If someone else has changed "master" in the
meantime, we'll need to update the change to apply cleanly to master.

Once someone has given your change the "+2", the "Submit" button shows up, and
we can can hit that to integrate the change into master.  The change should be
replicated to GitHub within about 30 seconds.


## Using cr.joyent.us with an existing local workspace

Suppose you've been working on a project from the GitHub copy, and someone has
imported that project into cr.joyent.us, and you want to start using Gerrit for
code review.  All you need to do is add a new Git **remote**:

    git remote add cr ssh://YOURUSERNAME@cr.joyent.us/PROJECT_GITHUB_ACCOUNT/PROJECT_NAME.git

PROJECT\_GITHUB\_ACCOUNT is usually `joyent`.  For example, if `davepacheco` had
a local copy of https://github.com/joyent/illumos-joyent, he'd do this:

    git remote add cr ssh://davepacheco@cr.joyent.us/joyent/illumos-joyent.git

Now you can use the same instructions from the "quick start" above.  Briefly:

    # Submit code for review as a NEW change in Gerrit.
    git push cr HEAD:refs/for/master

    # Submit a new patchset for existing change XYZ in Gerrit
    git push cr HEAD:refs/changes/XYZ

See the Gerrit docs for more information [on special references like
refs/for/... and
refs/changes/...](https://cr.joyent.us/Documentation/access-control.html#references_special)
rather than `refs/for/master`.


## Importing an existing GitHub repository

Unfortunately, only administrators can usefully create projects, so the easiest
thing is to have one of them do this for you.

Once a repository has been imported:

* **All subsequent pushes should go through Gerrit.**  People should stop
  pushing to the GitHub copy.  Please notify people who might push to the
  repository (e.g., by emailing "devs").  Ideally, we would turn off the ability
  to push to GitHub, but we have not written any tooling or documentation for
  this yet.
* Any changes pushed to "master" in Gerrit will be replicated to GitHub.
* GitHub remains the repository of record for automated builds and other
  tooling.

Note that while we don't want to allow pushes to GitHub and Gerrit
simultaneously, we can easily go back to a Gerrit-less world if we decide to by
simply removing the project from Gerrit and re-enabling GitHub push access.


## Creating a new repository

By far, the easiest way to create new repositories is to:

1. Create the repository on GitHub.
2. Push a commit to the GitHub repository (master branch).  This can be the
   first substantive commit you want in the repo or an empty commit if you want
   to use code review for the first substantive commit.
3. Have an administrator import the repository from GitHub.

At this point, the project should be fully functional on Gerrit.  Changes that
go through code review on Gerrit and are ultimately submitted (integrated into
master) will be replicated to GitHub.  Changes pushed directly to master on
Gerrit (bypassing code review) will also be replicated to GitHub.  


## Merging from upstream repositories

The illumos-joyent repository currently merges changes from upstream without
review.  To do this, the merge process should look exactly the same as before,
except that users should push directly to "cr.joyent.us".  If you've used the
above instructions to add a remote for cr.joyent.us, then it looks like this:

    $ git push cr master

Or, to configure "git push" of master to always push to cr.joyent.us:

    $ git push -u cr master

and then subsequent pushes can just use `git push`.

In order to do this, your cr.joyent.us user has to have an additional privilege,
which is the ability to push merge commits to this repository.  Talk to an
administrator to set this up.

If you need to do this for any repository _other_ than illumos-joyent, talk to
dap to make sure your use-case is covered.


## FAQ

### What do I have to do right now?

If you work on any Triton or Manta repository:

1. If you have not yet done so, please read [RFD
   45](https://github.com/joyent/rfd/tree/master/rfd/0045).
2. Follow the new user instructions at the top of this document.
3. For any Triton or Manta repository that you work on, **pay attention for any
   notice that it's been imported into Gerrit.  Once that's happened, stop
   pushing to GitHub** and follow the above docs for "Using Gerrit with an
   existing workspace".
4. For any Triton or Manta repository that you are responsible for, when you
   have some time, please follow the instructions above for importing that
   repository into Gerrit.  Feel free to pick up other repos as well, but if
   there's someone else that ought to be involved (i.e., someone else that tends
   to be responsible for that repo), please coordinate with them.

### Which repositories are going to use cr.joyent.us?

We're planning on using cr.joyent.us for code review on all repositories that
directly make up Triton and Manta.  That would at least include the repositories
on github.com/joyent that start with "sdc-" or "manta-", plus node modules and
other repositories that are obviously tied to Triton and Manta (e.g.,
"node-sdc-clients", "moray").

We can easily add support for other repositories, including components like
ContainerPilot and general-purpose modules that happen to be included in Triton
or Manta (e.g., `node-jsprim`).  That's up to project owners at this point.


### Which repositories have already been transitioned to cr.joyent.us?

See the [full list of repositories that live on
cr.joyent.us](https://cr.joyent.us/#/admin/projects/).


### After a repository has been imported into cr.joyent.us, where's the repository of record?  Is it Gerrit or GitHub?

**GitHub remains the repository of record.**  Automated builds and other tooling
(e.g., searching the code base) can still use GitHub.  You can clone
repositories from either Gerrit or GitHub.  They should always be in sync.  (The
nice thing about this is that if we decide to abandon Gerrit for whatever
reason, we can do that very easily.)

**All pushes should go through the Gerrit server, even when bypassing code
review.**  Remember, Gerrit is a full-fledged Git server, and even if we decide
to skip code review (e.g., for very early projects or for merges from upstream),
we still want to push to Gerrit so that the changes are reflected there and then
replicated to GitHub.


### What do we do if someone accidentally pushes to GitHub instead of Gerrit?

If someone pushes to GitHub, changes cannot be replicated from Gerrit
to GitHub until the Gerrit copy is updated with that change.

Gerrit will need to be updated with whatever was pushed to GitHub.  As long as
nobody has integrated a change from inside Gerrit or pushed to Gerrit's "master"
directly, this is easy: just push the current GitHub "master" to cr.joyent.us.
Currently, only administrators have privileges to do this, but that's just to
minimize accidental pushes to "master".

If GitHub and Gerrit have explicitly diverged (i.e., there are commits in both
places that are not present in the other), we'll likely have to force-push the
Gerrit master to match the GitHub master and then re-apply whatever changes had
been integrated via Gerrit.  Obviously, we'd rather avoid this.


### Can we enforce that people don't accidentally push to GitHub instead of Gerrit?

Help is needed here.  GitHub appears to support restricting pushes, but most of
the engineering team are effectively GitHub superusers for the Joyent
organization, which bypasses all such restrictions.  It would be great if we
could investigate how to manage GitHub access control so that people still have
the permissions they need to do everyday work (including creating new repos),
but we can still enforce push restrictions to avoid the above problem.


### What are the exact policies around code review and voting?

Please review the [Gerrit semantics around voting on changes](https://cr.joyent.us/Documentation/config-labels.html#label_Code-Review).  As a quick review:

* Votes are -2, -1, 0, +1, or +2.
* A "-2" vote is a veto: it means you're absolutely not okay with the change.
* A "-1" vote is a less strong wait to vote against a change.  It means you're
  not happy with it as-is, but you're not actually vetoing the change. 
* A "+1" vote is a thumbs-up: you're happy with the change as-is, but you want
  someone else to approve it.
* A "+2" vote is an approval to integrate the change.
* "0" is a way of leaving feedback without expressing an opinion on the change.
* Votes do not get added together.  Two +1s do not make a +2, for example.  You
  need someone to actually "+2" it to have a +2.

We're using the default Gerrit policy for submission, which means that in order
to submit a change (i.e., to integrate it into master):

* There must be at least one +2 vote.
* There must be no -2 votes.

In our deployment, the voting gets reset when somebody submits a new patchset.
If you change the code, you need reviewers to take another look.  The only
exception is for patchsets that only affect the commit messages.  Votes are
preserved when a new patchset is submitted that only changes the commit message.

We're not looking to make significant changes from our existing policy.  The
expectation is that all new code changes for Triton and Manta get reviewed by at
least one other person.  Any member of the engineering team (and any community
members to whom we delegate access) can +2 any change to any repository.  That
means you can even +2 your own change.  But the expectation is that people will
seek out feedback from others (even if there's nobody else who's very familiar
with the code).


### How will we handle changes that need to be kept secret (e.g., security fixes)?

This case is extremely rare, but it does come up.  We have not tried this out
yet, but there are two options:

1. Gerrit supports _draft_ reviews, which are not visible by default.  We can
   keep these hidden until they're finally integrated.
2. For these rare cases only, people could use some other code review mechanism
   (e.g., webrevs in Manta) and then push the change directly to master when
   it's ready to be opened up.


### If Gerrit requires a single commmit per change, how can I maintain multiple local commits?

If you want to keep local commits solely to keep track of what you've sent out
for review, then use patchsets for that.  Reviewers can diff any pair of
patchsets, and people can also "git checkout" any patchset.

It's pretty common that people want to keep lots of local commits separately
from what they submit to Gerrit.  You can do this, too.  It's just that in order
to push a new patchset, you have to create a single, squashed commit and push
_that_ to cr.joyent.us.  (You can keep all the other commits, though!)

The most robust way to do this is to:

1. Make sure all of your changes are committed to your working branch.
1. Checkout a new, temporary branch based on the upstream master.
2. Cherry-pick all of your commits onto this branch.
3. Squash all of these commits.
4. Push the squashed commit to Gerrit.
5. Checkout your working branch again.

At the end of this, you'll have pushed a single, squashed commit representing
all of your work, but your working directory will still be on the branch that
has all of your smaller commits.

Let's say you're keeping all of your commits on a local branch called
`WORKING_BRANCH`.  (This can be "master" or any other branch.) When you want to
submit a new patchset:

    # Make sure that you're on WORKING_BRANCH and that you've got no
    # uncommitted changes.
    $ git status

    # Check out a temporary branch to store the squashed commit.  This branch
    # should be based on the upstream master.  You can call this branch
    # whatever you like.
    $ git checkout -b TEMP_BRANCH cr/master

    # Apply your local commits to this branch.
    $ git cherry-pick TEMP_BRANCH..WORKING_BRANCH

    # Squash all of the changes with "git rebase".
    $ git rebase -i cr/master

    # Push the new patchset for review (see above for details)
    $ git push cr refs/changes/XYZ

    # Switch back to your working branch.
    $ git checkout WORKING_BRANCH

Some tooling could be helpful here.

As long as you started with no uncommitted changes, this procedure will never
lose any data, and you'll wind up in the same state you started: on your working
branch with all of your local commits.

At this point, you can delete TEMP\_BRANCH if you want, or you can use it for
the next patchset by resetting it with `git reset --hard cr/master`.


### Who can become an administrator?

Anyone can sign up to help run cr.joyent.us, but you should not need
administrative privileges to do anything that's part of the normal workflow
except for importing a new project.  We've set up relatively fine-grained access
control for most other operations.  As an administrator, the safeties are off,
and you can easily end up doing the wrong thing (e.g., pushing to master and
bypassing code review).  For that reason, we're trying to keep the group as
small as we can.  

If you do want to sign up to help run cr.joyent.us as an administrator, check
out the [operator guide](../operator/README.md) first and then talk to an
existing administrator to be added to the group.
