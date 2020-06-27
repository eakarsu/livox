<?php
/*
* Contact Form Class
*/


header('Cache-Control: no-cache, must-revalidate');
header('Expires: Mon, 26 Jul 1997 05:00:00 GMT');
header('Content-type: application/json');

$admin_email = 'info@eno.com.tr'; // Your Email


class Newsletter_Form{
	function __construct($details, $email_admin){
		
		
		$this->email = trim($details['emailInputNewsletter']);
		$this->subject = 'Newsletter request'; // Subject 
	
		$this->email_admin = $email_admin;
		
		$this->response_status = 1;
		$this->response_html = '';
		
		$this->message ='New Newsletter request from your site Email: '.$this->email;
		
	}


	private function validateEmail(){
		$regex = '/^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i';
	
		if($this->email == '') { 
			return false;
		} else {
			$string = preg_replace($regex, '', $this->email);
		}
	
		return empty($string) ? true : false;
	}


	private function validateFields(){

		// Check email
		if(!$this->email)
		{
			$this->response_html .= '<div class="alert alert-warning alert-dismissable"><button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button><strong>Warning!</strong> Please enter your email address</div>';
			$this->response_status = 0;
		}
		
		// Check valid email
		if($this->email && !$this->validateEmail())
		{
			$this->response_html .= '<div class="alert alert-warning alert-dismissable"><button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button><strong>Warning!</strong> Please enter a valid email address</div>';
			$this->response_status = 0;
		}
	}


	private function sendEmail(){
		$mail = mail($this->email_admin, $this->subject, $this->message,
			 "From: ".$this->name." <".$this->email.">\r\n"
			."Reply-To: ".$this->email."\r\n"
		."X-Mailer: PHP/" . phpversion());
	
		if($mail)
		{
			$this->response_status = 1;
			$this->response_html = '<div class="alert alert-success alert-dismissable"><button type="button" class="close" data-dismiss="alert" aria-hidden="true">&times;</button><strong>Thank you</strong> Your message has been delivered</div>';
		}
	}


	function sendRequest(){
		$this->validateFields();
		if($this->response_status)
		{
			$this->sendEmail();
		}

		$response = array();
		$response['status'] = $this->response_status;	
		$response['html'] = $this->response_html;
		
		echo json_encode($response);
	}
}


$contact_form = new Newsletter_Form($_POST, $admin_email);
$contact_form->sendRequest();

?>