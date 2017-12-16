// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import Socket from "./socket"
//import { Socket } from "phoenix";
let token = window.userToken
if (document.getElementById("user"))
    var user = {name: document.getElementById("user").innerText}
else 
    var user = {name: "", email: "", pass: ""}

user.token = token


let socket = new Socket("/socket", {params: {user: user}})
socket.connect()

console.log(token)

//define a room
let timeline = socket.channel("timeline:feed")

timeline.on("tweet:new", tweet => {
    console.log(tweet)
    renderTweet(tweet)
})

timeline.on("tweet:re", tweet => {
    renderRetweet(tweet)
})

timeline.on("followers:update", allfollowers => {
    renderFollowers(allfollowers.followers)
})

timeline.on("hashtags:update", tags => {
    console.log(tags.tags)
    renderHashtags(tags.tags)
})

timeline.join()

//update followers list
if (user.name != ""){
    timeline.push("followers:get", user)
}


let tweetInput = document.getElementById("newTweet")
if(tweetInput)
{
    tweetInput.addEventListener("keypress", (e) => {
        if(e.keyCode == 13 && tweetInput.value != ""){
            timeline.push("tweet:new", tweetInput.value)
            tweetInput.value = ""
        }
    })
}


let renderHashtags = (hashtagTweets) => {
    //console.log("Hashtags:")
    //console.log(hashtagTweets)

    hashtagTweets.forEach(createHashtagTweet)


}

let createHashtagTweet = (hashTweet) => {
    //create an HTML element li for the new follower
    let hashElement = document.createElement("li")
    hashElement.innerHTML = `
        <h5>${hashTweet}</h5>
    `
    hashtagsList.appendChild(hashElement)
    hashtagsList.scrollTop = hashtagsList.scrollHeight;
}

let renderFollowers = (followers) => {
    //console.log("Followers:")
    //console.log(followers)

    /*
    var index = followers.indexOf(user);
    if(index > -1){
       console.log("culprit found")
       followers.splice(index, 1) 
    }
    */
    followers.forEach(createFollower)    
    


}

let createFollower = (follower) => {
    //create an HTML element li for the new follower
    let followerElement = document.createElement("li")
    followerElement.innerHTML = `
        <h4 style="color: #FF5533">${follower}</h4>
    `
    followersList.appendChild(followerElement)
    followersList.scrollTop = followersList.scrollHeight;
}


let tweetList = document.getElementById("tweetList")
let renderTweet1 = (tweet) => {
    //create an HTML element li for the new tweet
    let tweetElement = document.createElement("li")
    tweetElement.innerHTML = `
        <b>${tweet.user}</b>
        <p>${tweet.body}
    `
    tweetList.appendChild(tweetElement)
    tweetList.scrollTop = tweetList.scrollHeight;
}


function retweet_handler() {
    let li_id = document.getElementById("li_id")
    let msg = li_id.innerText.split(":")
    var ruser = {
        name: user.name,
        original_user: msg[0].substr(1, (msg[0].length)-2),
        tweet: msg[1].substr(1),
        full_message: li_id.innerText
    }
    timeline.push("tweet:re", ruser)
}

let checkIfFollower = (user, followers) => {
    if (followers.indexOf(user) >= 0) 
        return true
    else
        return false
}

let renderTweet = (tweet) => {

    var followers = tweet.followers

    if(checkIfFollower(user.name, followers)){

        //console.log("Followers for Tweet:")
        //console.log(followers)

        let tweetElement = document.createElement("li")

        let retweetBtn = document.createElement("button")
        retweetBtn.className = "btn btn-danger retweet"
        retweetBtn.id = "retweet_${tweet.user}"
        retweetBtn.innerHTML = "Retweet"
        retweetBtn.addEventListener('click', retweet_handler, false)

        tweetElement.innerHTML = `
            <p id="li_id">
            <b>@${tweet.user} : </b> <i> ${tweet.body} </i> </p>
        `
        tweetElement.appendChild(retweetBtn)
        tweetList.appendChild(tweetElement)
        tweetList.scrollTop = tweetList.scrollHeight;
}
}

let renderRetweet = (tweet) => {

    var followers = tweet.followers
    if(checkIfFollower(user.name, followers)){
        let tweetElement = document.createElement("li")

        let retweetBtn = document.createElement("button")
        retweetBtn.className = "btn btn-danger retweet"
        retweetBtn.id = "retweet_${tweet.user}"
        retweetBtn.innerHTML = "Retweet"
        retweetBtn.addEventListener('click', retweet_handler, false)

        let message = tweet.body.split(':')
        let msg = {
            user: message[0].substring(1),
            tweet: message[1].substring(1)
        }


        tweetElement.innerHTML = `
            <p id="reli_id">
            <b>@${tweet.user} : </b> retweeted <br/> &nbsp;<i> <b> ${msg.user} : </b> ${msg.tweet} </i> </p>
        `
        tweetElement.appendChild(retweetBtn)
        tweetList.appendChild(tweetElement)
        tweetList.scrollTop = tweetList.scrollHeight;
}
}


//For following
let to_follow = document.getElementById("to_follow_username")
if ((to_follow))
{
    to_follow.addEventListener("keypress", (e) => {
        if(e.keyCode == 13 && to_follow.value != ""){
            var follow = {
                current_username: user.name,
                to_follow_username: to_follow.value
            }
            timeline.push("follow", follow)
            to_follow.value = ""
            //timeline.push("followers:get", user)
        }
    })
}

//For hashtags
let hashtag = document.getElementById("hashtag")
if ((hashtag))
{
    hashtag.addEventListener("keypress", (e) => {
        if(e.keyCode == 13 && hashtag.value != ""){
            var h = {
                hashtag: hashtag.value
            }
            timeline.push("hashtags:get", h)
            to_follow.value = ""
            //timeline.push("followers:get", user)
        }
    })
}

