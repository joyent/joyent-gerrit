# cr.joyent.us new user instructions

## Getting help

For help with specific steps or configuration, check out the [Gerrit User
Guide](https://cr.joyent.us/Documentation/intro-user.html).

**Note that we make one major departure from Gerrit standard practice:** rather
than putting Change-Id into commit messages, we have people push new patchsets
to
[refs/changes/...](https://cr.joyent.us/Documentation/access-control.html#_refs_changes).

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


## Importing an existing GitHub repository

Unfortunately, only administrators can usefully create projects, so the easiest
thing is to have one of them do it.


## Using Gerrit with an existing local workspace

Suppose you've been working on a project from the GitHub copy, and someone has
imported that project into cr.joyent.us, and you want to start using Gerrit for
code review.  All you need to do is add a new Git **remote**:

    git remote add cr ssh://YOURUSERNAME@cr.joyent.us/GITHUB_ACCOUNT/PROJECT_NAME.git

GITHUB\_ACCOUNT is usually `joyent`.  For example, if you had a local copy of
https://github.com/joyent/illumos-joyent, you'd do this:

    git remote add cr ssh://YOURUSERNAME@cr.joyent.us/joyent/illumos-joyent.git

**Before**, when pushing to repos on GitHub, you'd probably have run:

    git push

which (depending on your settings) is likely short for

    git push origin master

This actually means: "push changes from my local `master` branch to the remote
branch called `master`".

**Now**, when you're ready to submit something for review, you'll use the `cr`
remote, and you'll do something like this:

    git push cr HEAD:refs/for/master

Breaking this down:

* You're using the `cr` remote because you're pushing to cr.joyent.us, not
  GitHub.
* You're not pushing `master` because the change won't be applied to master
  until it's gone through code review.  Instead, you'll be pushing to a
  special reference on the Gerrit server called `refs/for/master`.  Gerrit
  interprets to mean that a new change should be created for this commit.
* Because you don't have a local reference called `refs/for/master`, you have to
  explicitly specify the _source_ (i.e., what you're pushing), which is `HEAD`.

Note that for follow-up changes (i.e., new patchsets for the same change),
you'll be pushing to a different [special reference that starts with
refs/changes
](https://cr.joyent.us/Documentation/access-control.html#_refs_changes) rather
than `refs/for/master`.  If none of this makes sense to you, check out the
Gerrit user docs (see Getting Help above).
