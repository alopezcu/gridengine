/*___INFO__MARK_BEGIN__*/
/*************************************************************************
 *
 *  The Contents of this file are made available subject to the terms of
 *  the Sun Industry Standards Source License Version 1.2
 *
 *  Sun Microsystems Inc., March, 2001
 *
 *
 *  Sun Industry Standards Source License Version 1.2
 *  =================================================
 *  The contents of this file are subject to the Sun Industry Standards
 *  Source License Version 1.2 (the "License"); You may not use this file
 *  except in compliance with the License. You may obtain a copy of the
 *  License at http://gridengine.sunsource.net/Gridengine_SISSL_license.html
 *
 *  Software provided under this License is provided on an "AS IS" basis,
 *  WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING,
 *  WITHOUT LIMITATION, WARRANTIES THAT THE SOFTWARE IS FREE OF DEFECTS,
 *  MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE, OR NON-INFRINGING.
 *  See the License for the specific provisions governing your rights and
 *  obligations concerning the Software.
 *
 *   The Initial Developer of the Original Code is: Sun Microsystems, Inc.
 *
 *   Copyright: 2001 by Sun Microsystems, Inc.
 *
 *   All Rights Reserved.
 *
 ************************************************************************/
/*___INFO__MARK_END__*/
/**
 *  Generated from java_jmx_jgdi.jsp
 *  !!! DO NOT EDIT THIS FILE !!!
 */
 

<%
    /*
    * Helper class to initialize option Map.
    */
   class MapInit {
      java.util.Map<String, String> nameToOpt = new java.util.HashMap<String, String>();

      //TODO LP: Is already defined in OptionAnnotation, however annotation not seen in this context
      static final int MAX_ARG_VALUE = Integer.MAX_VALUE / 8;
      
      public MapInit() {
         nameToOpt.put("Calendar","cal");
         nameToOpt.put("Checkpoint","ckpt");
         nameToOpt.put("Configuration","conf");
         nameToOpt.put("ClusterQueue","q");
         nameToOpt.put("ExecHost","e");
         nameToOpt.put("Hostgroup","hgrp");
         nameToOpt.put("ParallelEnvironment","p");
         nameToOpt.put("Project","prj");
         //nameToOpt.put("ResourceQuotaSet","rqs");
         nameToOpt.put("User","user");
      }
      
      java.util.Map<String, String> getMap() {
         return nameToOpt;
      }
      
      public void genDefaultMethodsForType(String type) {
         if (!nameToOpt.containsKey(type)) {
            throw new IllegalStateException("<QConfCommand> failed: Unknown option type "+type);
         }
         String opt = (String) nameToOpt.get(type);
         genAddMethod(type, "-a"+opt, 0, 1);
         genAddFromFileMethod(type, "-A"+opt, 1, 0);
         genModifyMethod(type, "-m"+opt, 1, 0);
         genModifyFromFileMethod(type, "-M"+opt, 1, 0);
         genShowMethod(type, "-s"+opt, 1, MAX_ARG_VALUE);
         genShowListMethod(type, "-s"+opt+"l", 0, 0);
         genDeleteMethod(type, "-d"+opt, 1, MAX_ARG_VALUE);
      }
      
      void genAddMethod(String objectType, String optionString, int mandatory, int optional) {  
      %>
   /**
    *   Implements qconf <%=optionString%> option
    *   @param  oi <b>OptionInfo</b> option enviroment object
    *   @throws JGDIException on any error on the GDI layer
    */
   @OptionAnnotation(value = "<%=optionString%>", min = <%=mandatory%>, extra = <%=optional%>)
   public void add<%=objectType%>(final OptionInfo oi) throws JGDIException {
      String arg = oi.getFirstArg();
      List<JGDIAnswer> answer = new LinkedList<JGDIAnswer>();
      // create an object with defaults set
      <%=objectType%> obj = new <%=objectType%>Impl(true);
      if (arg != null) {
         obj.setName(arg);
      }
      String userTypedText = runEditor(GEObjectEditor.getConfigurablePropertiesAsText(obj));

      if (userTypedText != null) {
         GEObjectEditor.updateObjectWithText(jgdi, obj, userTypedText);
         jgdi.add<%=objectType%>WithAnswer(obj, answer);
         printAnswers(answer);
      }
      oi.optionDone();
   }   
   <%
       } //end genAddMethod
       
       void genAddFromFileMethod(String objectType, String optionString, int mandatory, int optional) {
       %>
   /**
    *   Implements qconf <%=optionString%> option
    *   @param  oi <b>OptionInfo</b> option enviroment object
    *   @throws JGDIException on any error on the GDI layer
    */
   @OptionAnnotation(value = "<%=optionString%>", min = <%=mandatory%>, extra = <%=optional%>)
   public void addFromFile<%=objectType%>(final OptionInfo oi) throws JGDIException {
      final String fileName = oi.getFirstArg();
      List<JGDIAnswer> answer = new LinkedList<JGDIAnswer>();
      <%=objectType%> obj = new <%=objectType%>Impl(true);
      String inputText = readFile(fileName);
      String setNameMethod = "setName";
      <%if (objectType.equals("Configuration")) {%>
      final String keyAttrValue = new File(fileName).getName();
      <%} else {%>
      final String keyAttrValue = getKeyAttributeValueFromString(pw, "<%=objectType%>", fileName, inputText);
      <% } %>
      if (keyAttrValue == null) {
         return;
      }
      obj.setName(keyAttrValue);
      GEObjectEditor.updateObjectWithText(jgdi, obj, inputText);
      jgdi.add<%=objectType%>WithAnswer(obj, answer);
      printAnswers(answer);
      oi.optionDone();
   }  
   <%
       } //end genAddFromFileMethod  
       
       void genModifyMethod(String objectType, String optionString, int mandatory, int optional) {
       %>
   /**
    *   Implements qconf <%=optionString%> option
    *   @param  oi <b>OptionInfo</b> option enviroment object
    *   @throws JGDIException on any error on the GDI layer
    */
   @OptionAnnotation(value = "<%=optionString%>", min = <%=mandatory%>, extra = <%=optional%>)
   public void modify<%=objectType%>(final OptionInfo oi) throws JGDIException {
      final String arg = oi.getFirstArg();
      List<JGDIAnswer> answer = new LinkedList<JGDIAnswer>();
      <% if ( mandatory == 0 && optional == 0 ) { %>
      <%=objectType%> obj = jgdi.get<%=objectType%>WithAnswer(answer);
      <% } else { %>
      <%=objectType%> obj = jgdi.get<%=objectType%>WithAnswer(arg, answer);
      <% }%>
      if (obj != null) {
         //clear the answers from the get request
         answer.clear();
         String userTypedText = runEditor(GEObjectEditor.getConfigurablePropertiesAsText(obj));
         if (userTypedText != null) {
            GEObjectEditor.updateObjectWithText(jgdi, obj, userTypedText);
            jgdi.update<%=objectType%>WithAnswer(obj, answer);
         }
         printAnswers(answer);
      } else {
         String msg = getErrorMessage("InvalidObjectArgument", oi.getOd().getOption(), arg, null);
         pw.println(msg);
      }
      oi.optionDone();
   }  
   <%
       } //end genModifyMethod  
       
       void genModifyFromFileMethod(String objectType, String optionString, int mandatory, int optional) {
       %>
   /**
    *   Implements qconf <%=optionString%> option
    *   @param  oi <b>OptionInfo</b> option enviroment object
    *   @throws JGDIException on any error on the GDI layer
    */
   @OptionAnnotation(value = "<%=optionString%>", min = <%=mandatory%>, extra = <%=optional%>)
   public void modifyFromFile<%=objectType%>(final OptionInfo oi) throws JGDIException {
      final String fileName = oi.getFirstArg();
      List<JGDIAnswer> answer = new LinkedList<JGDIAnswer>();
      String inputText = readFile(fileName);
      <%=objectType%> obj;
      <%if (objectType.equals("SchedConf")) {%>
      obj = jgdi.getSchedConf();
      <%} else {%>
      final String keyAttrValue = getKeyAttributeValueFromString(pw, "<%=objectType%>", fileName, inputText);
      if (keyAttrValue == null) {
         return;
      }
      obj = jgdi.get<%=objectType%>(keyAttrValue);
      <%} %>
      GEObjectEditor.updateObjectWithText(jgdi, obj, inputText);
      jgdi.update<%=objectType%>WithAnswer(obj, answer);
      printAnswers(answer);
      oi.optionDone();
   }  
   <%
       } //end genModifyFromFileMethod  
       
       void genShowMethod(String objectType, String optionString, int mandatory, int optional) {
       %>
   /**
    *   Implements qconf <%=optionString%> option
    *   @param  oi <b>OptionInfo</b> option enviroment object
    *   @throws JGDIException on any error on the GDI layer
    */
   @OptionAnnotation(value = "<%=optionString%>", min = <%=mandatory%>, extra = <%=optional%>)
   public void show<%=objectType%>(final OptionInfo oi) throws JGDIException {
      final String arg = oi.getFirstArg();
      List<JGDIAnswer> answer = new LinkedList<JGDIAnswer>();
      <% if ( mandatory == 0 && optional == 0 ) { %>
      <%=objectType%> obj = jgdi.get<%=objectType%>WithAnswer(answer);
      <% } else { %>
      <%=objectType%> obj = jgdi.get<%=objectType%>WithAnswer(arg, answer);
      <% }%>
      printAnswers(answer);
      //Display error message in no such object exists
      if (obj == null) {
          pw.println(getErrorMessage("InvalidObjectArgument", oi.getOd().getOption(), arg, "Object \""+arg+"\" does not exist"));
          return;
      }
      //Show the object
      String text = GEObjectEditor.getAllPropertiesAsText(obj);
      pw.print(text);
   } 
   <%
       } //end genShowMethod  
       
       void genShowListMethod(String objectType, String optionString, int mandatory, int optional) {
       %>
   /**
    *   Implements qconf <%=optionString%> option
    *   @param  oi <b>OptionInfo</b> option enviroment object
    *   @throws JGDIException on any error on the GDI layer
    */
   @OptionAnnotation(value = "<%=optionString%>", min = <%=mandatory%>, extra = <%=optional%>)
   public void showList<%=objectType%>(final OptionInfo oi) throws JGDIException {
      List<JGDIAnswer> answer = new LinkedList<JGDIAnswer>();
      List< <%=objectType%> > list = (List< <%=objectType%> >)jgdi.get<%=objectType%>ListWithAnswer(answer);
      printAnswers(answer);
      List<String> values = new LinkedList<String>();
      for (<%=objectType%> obj : list) {
         values.add(obj.getName());
      }
      <% if (objectType.equals("Configuration") || objectType.equals("UserSet")) { %>
      values.remove("global");
      <%} else if (objectType.equals("ExecHost")) { %>
      values.remove("global");
      values.remove("template");
      <% } %>
      //Show correct error message if list is empty
      if (values.size() == 0) {
          pw.println(getErrorMessage("NoObjectFound", oi.getOd().getOption(), "", "No object found"));
          return;
      }
      //Otherwise print sorted list
      Collections.sort(values);
      for (String val : values) {
        pw.println(val);
      }
      oi.optionDone();
   }   
   <%
       } //end genShowListMethod
       
       void genDeleteMethod(String objectType, String optionString, int mandatory, int optional) {
       %>
   /**
    *   Implements qconf <%=optionString%> option
    *   @param  oi <b>OptionInfo</b> option enviroment object
    *   @throws JGDIException on any error on the GDI layer
    */
   @OptionAnnotation(value = "<%=optionString%>", min = <%=mandatory%>, extra = <%=optional%>)
   public void delete<%=objectType%>(final OptionInfo oi) throws JGDIException {
      List<JGDIAnswer> answers = new LinkedList<JGDIAnswer>();
      int size = oi.getArgs().size();
      final String[] vals = oi.getArgs().toArray(new String[size]);
      oi.optionDone();
      jgdi.delete<%=objectType%>sWithAnswer(vals, answers);
      printAnswers(answers);
   }
   <%
       } //end genDeleteMethod  
       
  } //end Class MapInit
  
  
  // ---------------------------------------------------------------------------
  // Build Generator instances
  // ---------------------------------------------------------------------------
  MapInit init = new MapInit();
%>
package com.sun.grid.jgdi.util.shell;

import com.sun.grid.jgdi.JGDI;
import com.sun.grid.jgdi.JGDIException;
import com.sun.grid.jgdi.configuration.*;
import com.sun.grid.jgdi.util.shell.AnnotatedCommand;
import com.sun.grid.jgdi.util.shell.editor.EditorUtil;
import com.sun.grid.jgdi.util.shell.editor.GEObjectEditor;
import com.sun.grid.jgdi.util.shell.editor.TextEditor;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.LineNumberReader;
import java.io.PrintWriter;
import java.io.StringReader;
import java.util.LinkedList;
import java.util.Collections;
import java.util.List;

/**
 * Generated abstract class for handling generic JGDI objects.
 * Implements generic qconf command options.
 * NOTE: QConfCommand should extend this class.
 * @see com.sun.grid.jgdi.util.shell.QConfCommand
 */
public abstract class QConfCommandGenerated extends AnnotatedCommand {

   
<% for (String objType : init.getMap().keySet()) {
     init.genDefaultMethodsForType(objType);
  }
  //SchedConf
  init.genModifyMethod("SchedConf","-msconf", 0, 0);
  init.genModifyFromFileMethod("SchedConf", "-Msconf", 1, 0);
  init.genShowMethod("SchedConf", "-ssconf",0, 0);
  //UserSet
  init.genAddFromFileMethod("UserSet","-Au", 1, 0);
  init.genModifyMethod("UserSet", "-mu", 1, 0);
  init.genModifyFromFileMethod("UserSet","-Mu",  1, 0);
  init.genShowMethod("UserSet", "-su", 1, init.MAX_ARG_VALUE);
  init.genShowListMethod("UserSet", "-sul", 0, 0);
  //Operator
  init.genShowListMethod("Operator", "-so", 0, 0);
  //Manager
  init.genShowListMethod("Manager", "-sm", 0, 0);
  //SubmitHost
  init.genShowListMethod("SubmitHost", "-ss", 0, 0);
  //AdminHost
  init.genShowListMethod("AdminHost", "-sh", 0, 0);
  //ResourceQuotaSet
  init.genAddMethod("ResourceQuotaSet", "-arqs", 0, init.MAX_ARG_VALUE);
  init.genAddFromFileMethod("ResourceQuotaSet", "-Arqs", 1, 0);
  init.genModifyFromFileMethod("ResourceQuotaSet", "-Mrqs", 1, 0);
  init.genShowListMethod("ResourceQuotaSet", "-srqsl", 0, 0);
  init.genDeleteMethod("ResourceQuotaSet", "-drqs", 1, init.MAX_ARG_VALUE);
%>
  <%@include file="java_qconf_cmd.static"%>
}
