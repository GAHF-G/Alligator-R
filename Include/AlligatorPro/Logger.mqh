#pragma once

class Logger
  {
public:
   static void Info(const string component,const string message)
     {
      PrintFormat("{\"level\":\"INFO\",\"component\":\"%s\",\"msg\":\"%s\"}",component,message);
     }

   static void Warn(const string component,const string message)
     {
      PrintFormat("{\"level\":\"WARN\",\"component\":\"%s\",\"msg\":\"%s\"}",component,message);
     }

   static void Error(const string component,const string message)
     {
      PrintFormat("{\"level\":\"ERROR\",\"component\":\"%s\",\"msg\":\"%s\"}",component,message);
     }
  };
