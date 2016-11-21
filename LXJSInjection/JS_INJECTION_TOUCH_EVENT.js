/*!
 *@description:js注入代码，监听网页的touch事件
 *@发送协议格式：lxjsinject-touch://index#myweb:touch:start:123:123
 */

document.ontouchstart=function(event){
    x=event.targetTouches[0].clientX; 
    y=event.targetTouches[0].clientY; 
    document.location='lxjsinject-touch://index#myweb:touch:start:'+x+':'+y; 
};

document.ontouchmove=function(event){ 
    x=event.targetTouches[0].clientX; 
    y=event.targetTouches[0].clientY; 
    document.location='lxjsinject-touch://index#myweb:touch:move:'+x+':'+y; 
};

document.ontouchcancel=function(event){ 
    document.location='lxjsinject-touch://index#myweb:touch:cancel';
};

document.ontouchend=function(event){ 
    document.location='lxjsinject-touch://index#myweb:touch:end'; 
};
