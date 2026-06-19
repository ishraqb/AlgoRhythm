import * as cdk from "aws-cdk-lib";
import { Construct } from "constructs";
import * as dynamodb from "aws-cdk-lib/aws-dynamodb";
import * as cognito from "aws-cdk-lib/aws-cognito";
import * as appsync from "aws-cdk-lib/aws-appsync";
import { NodejsFunction } from "aws-cdk-lib/aws-lambda-nodejs";
import * as lambda from "aws-cdk-lib/aws-lambda";
import * as path from "path";

export class AlgoRhythmStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Single table: cards under PK "CARDS", user progress under PK "<cognito sub>".
    const table = new dynamodb.Table(this, "AlgoRhythmTable", {
      tableName: "AlgoRhythm",
      partitionKey: { name: "PK", type: dynamodb.AttributeType.STRING },
      sortKey: { name: "SK", type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      // Personal/dev project: tear down cleanly with `cdk destroy`.
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Email/password sign-up with verification. Free tier covers 50k MAUs.
    const userPool = new cognito.UserPool(this, "AlgoRhythmUserPool", {
      userPoolName: "AlgoRhythmUsers",
      selfSignUpEnabled: true,
      signInAliases: { email: true },
      autoVerify: { email: true },
      passwordPolicy: {
        minLength: 8,
        requireLowercase: true,
        requireUppercase: true,
        requireDigits: true,
        requireSymbols: false,
      },
      accountRecovery: cognito.AccountRecovery.EMAIL_ONLY,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Public app client (no secret) so the native app can call Cognito directly.
    const userPoolClient = userPool.addClient("AlgoRhythmAppClient", {
      authFlows: { userPassword: true, userSrp: true },
      generateSecret: false,
    });

    const api = new appsync.GraphqlApi(this, "AlgoRhythmApi", {
      name: "AlgoRhythmApi",
      definition: appsync.Definition.fromFile(
        path.join(__dirname, "..", "graphql", "schema.graphql")
      ),
      authorizationConfig: {
        // Default deny: every operation requires a valid Cognito user-pool token.
        defaultAuthorization: {
          authorizationType: appsync.AuthorizationType.USER_POOL,
          userPoolConfig: { userPool },
        },
      },
      xrayEnabled: false,
    });

    const commonFnProps = {
      runtime: lambda.Runtime.NODEJS_20_X,
      environment: { TABLE_NAME: table.tableName },
      timeout: cdk.Duration.seconds(10),
      memorySize: 256,
    };

    const getCardsFn = new NodejsFunction(this, "GetCardsByTopicFn", {
      ...commonFnProps,
      entry: path.join(__dirname, "..", "lambda", "getCardsByTopic.ts"),
      handler: "handler",
    });

    const updatePerfFn = new NodejsFunction(this, "UpdatePerformanceFn", {
      ...commonFnProps,
      entry: path.join(__dirname, "..", "lambda", "updateUserPerformanceTrack.ts"),
      handler: "handler",
    });

    const generateFn = new NodejsFunction(this, "GenerateCardsFn", {
      ...commonFnProps,
      entry: path.join(__dirname, "..", "lambda", "generateCards.ts"),
      handler: "handler",
    });

    // Least privilege: read-only where we only read, write-only where we only
    // write, and no table access at all for pure-compute generation.
    table.grantReadData(getCardsFn);
    table.grantWriteData(updatePerfFn);

    const getCardsDs = api.addLambdaDataSource("GetCardsDS", getCardsFn);
    getCardsDs.createResolver("GetCardsResolver", {
      typeName: "Query",
      fieldName: "getCardsByTopic",
    });

    const generateDs = api.addLambdaDataSource("GenerateDS", generateFn);
    generateDs.createResolver("GenerateResolver", {
      typeName: "Query",
      fieldName: "generateCards",
    });

    const updatePerfDs = api.addLambdaDataSource("UpdatePerfDS", updatePerfFn);
    updatePerfDs.createResolver("UpdatePerfResolver", {
      typeName: "Mutation",
      fieldName: "updateUserPerformanceTrack",
    });

    // Outputs consumed by scripts/write-config to produce the app's AppConfig.plist.
    new cdk.CfnOutput(this, "GraphQLEndpoint", { value: api.graphqlUrl });
    new cdk.CfnOutput(this, "UserPoolId", { value: userPool.userPoolId });
    new cdk.CfnOutput(this, "UserPoolClientId", { value: userPoolClient.userPoolClientId });
    new cdk.CfnOutput(this, "Region", { value: this.region });
    new cdk.CfnOutput(this, "TableName", { value: table.tableName });
  }
}
