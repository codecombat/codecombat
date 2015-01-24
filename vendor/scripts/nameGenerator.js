// http://leapon.net/files/namegen.html


NameGenerator = {};
NameGenerator.rnd = rnd = function rnd(minv, maxv){
  if (maxv < minv) return 0;
  return Math.floor(Math.random()*(maxv-minv+1)) + minv;
}

NameGenerator.getName = function getName(minlength, maxlength, prefix, suffix)
{
  prefix = prefix || '';
  suffix = suffix || '';
  //these weird character sets are intended to cope with the nature of English (e.g. char 'x' pops up less frequently than char 's')
  //note: 'h' appears as consonants and vocals
  var vocals = 'aeiouyh' + 'aeiou' + 'aeiou';
  var cons = 'bcdfghjklmnpqrstvwxz' + 'bcdfgjklmnprstvw' + 'bcdfgjklmnprst';
  var allchars = vocals + cons;
  //minlength += prefix.length;
  //maxlength -= suffix.length;
  var length = rnd(minlength, maxlength) - prefix.length - suffix.length;
  if (length < 1) length = 1;
  //alert(minlength + ' ' + maxlength + ' ' + length);
  var consnum = 0;
  //alert(prefix);
  /*if ((prefix.length > 1) && (cons.indexOf(prefix[0]) != -1) && (cons.indexOf(prefix[1]) != -1)) {
   //alert('a');
   consnum = 2;
   }*/
  if (prefix.length > 0) {
    for (var i = 0; i < prefix.length; i++) {
      if (consnum == 2) consnum = 0;
      if (cons.indexOf(prefix[i]) != -1) {
        consnum++;
      }
    }
  }
  else {
    consnum = 1;
  }

  var name = prefix;

  for (var i = 0; i < length; i++)
  {
    //if we have used 2 consonants, the next char must be vocal.
    if (consnum == 2)
    {
      touse = vocals;
      consnum = 0;
    }
    else touse = allchars;
    //pick a random character from the set we are goin to use.
    c = touse.charAt(rnd(0, touse.length - 1));
    name = name + c;
    if (cons.indexOf(c) != -1) consnum++;
  }
  name = name.charAt(0).toUpperCase() + name.substring(1, name.length) + suffix;
  return name;
}