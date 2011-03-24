function renderHtml(html)
{
	insertAfterHead(html)
}

function insertAfterHead(html_str) {
  alert("inserting html" + html_str);
  var elt = document.getElementByNumber(0);
  if(IsNetscape() || IsSafari()) {
    var x = document.createRange();
    try {
      x.setStartAfter(elt);
    }
    catch(err) {
      alert();
    }
//    x.setStartBefore(elt);
    x = x.createContextualFragment(html_str);
    elt.appendChild(x);
  }
  else if(IsMicrosoft()) {
    elt.insertAdjacentHTML("BeforeEnd",html_str);
//     elt.insertAdjacentHTML("AfterEnd",html_str);
  }
  else {
    alert("Sorry, this browser type not yet supported.");
  }

	
}
