await firebase.initializeApp
	apiKey: "AIzaSyBbWU8qaFxabXC-AddlqUBjhxDORc4T7eI"
	authDomain: "fakr-caeca.firebaseapp.com"
	databaseURL: "fakr-caeca.firebaseio.com"

auth = firebase.auth()
db = firebase.database()
game = meDb = usersDb = null
n = 0

auth.languageCode = "vi"
